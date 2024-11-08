
// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction{ //is Ownable {    
    uint private FloorValue ; //Valor inicial
    uint private StartDate  ;         //Fecha de inicio
    uint private Timeframe ;          //Duracion de subasta
    struct Offer {
        uint     date;        
        uint     offerAmount; 
        uint     excessAmount;              
    }
    address  offerWinAddress;  //Direccion ganando   
    uint     offerWinAmount;   //Oferta ganando      
    mapping(address => Offer) private offers;
    address[] private offerAddresses; //Lista de direcciones ofertantes para poder recorrerlas y mostrar todas las ofertas

    constructor () {
        FloorValue = 10 gwei;
        StartDate = block.timestamp;
        Timeframe = StartDate + 7 days;
    }
    event NewBid(address indexed bidder, uint amount);
    event EndAuction (string text);
    event AuctionExtended(uint newTimeframe);
    function AuctionEnded() internal {
       uint amountReturn;
       address addresReturn;
       require(block.timestamp >= Timeframe, "La subasta sigue vigente");
       for (uint i = 0; i < offerAddresses.length; i++) {
        if (offerAddresses[i] != offerWinAddress) {           
            amountReturn = offers[addresReturn].offerAmount *98 / 100;
            if (amountReturn == 0) {
                 continue; // Salteo ya devolvi o ya retiro
            }
           addresReturn = offerAddresses[i];           
           offers[addresReturn].offerAmount = 0;
           payable(addresReturn).transfer(amountReturn);
        }
    }
        emit EndAuction("La subasta ha terminado");
    }

     modifier extendAuctionIfNeeded() {     
        if (block.timestamp >= Timeframe - 10 minutes) {
            Timeframe += 10 minutes;  
            emit AuctionExtended(Timeframe);  
        }
        _;
    }
     
     

    function setOffer () external payable extendAuctionIfNeeded {        
      require(block.timestamp <= Timeframe, "La subasta ha terminado");  //Valido si esta activa la subasta
      if (offers[msg.sender].offerAmount == 0) {    //Verifico si ya realizo una oferta esa address
            offerAddresses.push(msg.sender);
        } else {
        //  Me fijo si ya esta ganando la subasta
        require(msg.sender != offerWinAddress, "Ya tienes la oferta mas alta");
      }
      require(msg.value >= offerWinAmount *105/100, "La oferta debe ser superior al menos en 5%");     //Verifico si la oferta es valida
      offers[msg.sender] = Offer({
            date: block.timestamp,
            offerAmount: msg.value,
            excessAmount: offers[msg.sender].offerAmount +  offers[msg.sender].excessAmount
        });       //Registro la oferta, y actualizo el excess si ya realizo oferta para que pueda retirar
        offerWinAmount = msg.value;   //Actualizo la oferta ganadora y la address podria hacerlo en una funcion 
        offerWinAddress = msg.sender; //y recorrer todas las address comparando las ofertas pero tendria que llamarla cada vez para los dos require de arriba
        emit NewBid(msg.sender, msg.value);        

    }
    
    function getWinnerOffer() external view returns(address) {
        return offerWinAddress;
    }
    
    function getWinnerAmount() external view returns(uint) {
        return offerWinAmount;
    }
     
    function showOffers () external view returns(address[] memory, uint[] memory){
        address[] memory offerors = new address[](offerAddresses.length);
        uint[] memory amounts = new uint[](offerAddresses.length);
        for (uint i = 0; i < offerAddresses.length; i++) {
        address offeror = offerAddresses[i];
        offerors[i] = offeror;
        amounts[i] = offers[offeror].offerAmount;
        }    
        return (offerors, amounts); 
    }

    function withdrawExcess() external payable {
        require(msg.value<=offers[msg.sender].excessAmount,"No tiene suficiente saldo para retirar");
        offers[msg.sender].excessAmount = offers[msg.sender].excessAmount-msg.value;
        payable(msg.sender).transfer(msg.value);
    }
    function getExcess() external view  returns(uint){
        return (offers[msg.sender].excessAmount);
        
    }
    function getTimeLeft() public view returns (uint _days, uint _hours, uint _minutes) {
        if (block.timestamp >= Timeframe) {
            return (0, 0, 0);  // Termino la subasta
        }

        uint timeLeft = Timeframe - block.timestamp;

        _days = timeLeft / 86400;             // Calculo los dias (1 dia = 86400 seconds)
        timeLeft %= 86400;                   // Actualizo el timeleft con el resto de segundos que quedan

        _hours = timeLeft / 3600;             // Calculo las horas (1 hora = 3600 seconds)
        timeLeft %= 3600;                    // Actualizo el timeleft con el resto de segundos que quedan

        _minutes = timeLeft / 60;             // Calculate minutes (1 minute = 60 seconds)
    }
}