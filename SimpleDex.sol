// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract SimpleDEX is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB; 
    
    event LiquidityAdded(address indexed owner, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed owner, uint256 amountA, uint256 amountB);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event PoolInitialized(address indexed owner, uint256 amountA, uint256 amountB);

    constructor(address _tokenA, address _tokenB)  Ownable(msg.sender)  {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);                    
    }

    function initializePool(uint256 amountA, uint256 amountB)  external onlyOwner {
        require(amountB == amountA * 4, "Invalid ratio: TokenB must be 4x TokenA");        
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA* 1e18),
            "Token A transfer failed"
        );
        require(
            tokenB.transferFrom(msg.sender, address(this), amountB* 1e18),
            "Token B transfer failed"
        );
        emit PoolInitialized(msg.sender, amountA* 1e18, amountB* 1e18);
    }


    // Agrega Liquidez
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Invalid amounts");   
        require(tokenB.balanceOf(address(this)) > 0 && tokenA.balanceOf(address(this)) > 0, "Pool Not Initialized");  
        uint256 ratioA = (tokenA.balanceOf(address(this)) * 1e18) / tokenB.balanceOf(address(this)); 
        uint256 ratioB = (tokenB.balanceOf(address(this)) * 1e18) / tokenA.balanceOf(address(this)); 

        // Verifico que la proporcion se mantenga al agregar liquidez
        require(
            amountA / amountB == ratioA || amountB/ amountA == ratioB,
            "Invalid liquidity ratio"
        );

        tokenA.transferFrom(msg.sender, address(this), amountA* 1e18);
        tokenB.transferFrom(msg.sender, address(this), amountB* 1e18);   

        emit LiquidityAdded(msg.sender, amountA* 1e18, amountB* 1e18);              
    }

    // Swap de tokens A=>B
    function swapAForB(uint256 amountA) external {
        require(amountA > 0, "Invalid amount");
        // Calculo la cantidad de B que compra
        uint256 reserveA = tokenA.balanceOf(address(this));
        uint256 reserveB = tokenB.balanceOf(address(this));
        uint256 amountB = getAmountOut(amountA, reserveA, reserveB);
        // Transfiero TokenA de la billetera al contrato
        tokenA.transferFrom(msg.sender, address(this), amountA* 1e18);                
        // Transfiero TokenB a la billetera
        tokenB.transfer(msg.sender, amountB* 1e18);

        emit Swap(msg.sender, address(tokenA), address(tokenB), amountA* 1e18, amountB* 1e18);
    }
    // Swap the tokens B=>A
    function swapBForA(uint256 amountB) external {
        require(amountB > 0, "Invalid amount");
        // Calculo la cantidad de A que compra
        uint256 reserveA = tokenA.balanceOf(address(this));
        uint256 reserveB = tokenB.balanceOf(address(this));
        uint256 amountA = getAmountOut(amountB, reserveB, reserveA);            
       
       // Transfiero TokenB de la billetera al contrato
        tokenB.transferFrom(msg.sender, address(this), amountB* 1e18);
        // Transfiero TokenA a la billetera
        tokenA.transfer(msg.sender, amountA* 1e18);

        emit Swap(msg.sender, address(tokenB), address(tokenA), amountB* 1e18, amountA* 1e18);
    }

    // Funcion Devuelve la cantidad de token de acuerdo a la formula de liquidez constante.
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
    // Saca liquidez
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {                   
        tokenA.transfer(msg.sender, amountA* 1e18);
        tokenB.transfer(msg.sender, amountB* 1e18);
        
        emit LiquidityRemoved(msg.sender, amountA* 1e18, amountB* 1e18);
    }
     // Muestra el balance actual
    function getReserves() external view returns (uint256, uint256) {
        return (
            tokenA.balanceOf(address(this))/ 1e18,
            tokenB.balanceOf(address(this))/ 1e18
        );
    }

    // Trae el precio
    function getPrice() external view returns (uint256 tokenAEquivalent,uint256 tokenBEquivalent) {
        uint256 reserveA = tokenA.balanceOf(address(this));
        uint256 reserveB = tokenB.balanceOf(address(this));
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        return (((reserveA * 1e18*100) / reserveB)/ 1e18, ((reserveB * 1e18*100) / reserveA)/ 1e18); // Multiplico por 100 Sino el precio del token a no se ve se trunca a 0
    }
}
