
// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract TokenA is ERC20, Ownable, ERC20Permit  {    
    uint decimal = 18;
    event Initialized(address indexed token, uint256 amount);  
    event Minted(address indexed to, uint256 amount);         
     constructor(address initialOwner)
        ERC20("TokenA", "TKA")
        Ownable(initialOwner)
        ERC20Permit("TokenA")
    {
        uint256 initialSupply = 10000000;
        _mint(initialOwner, initialSupply*10**decimal);       
        emit Initialized(address(this), initialSupply); 
    }
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Minted(to, amount); 
    }    
}