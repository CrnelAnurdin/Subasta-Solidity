
// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol"; trate de importar el ownable pero me tiraba un error el constructor

contract Auction  { 
    //Inicio Variables Entorno
    uint private FloorValue ; 
    uint private StartDate  ; 
    uint private Timeframe ;  
    uint public  offerWinAmount;  
    struct Offer {
        uint     date;        
        uint     offerAmount; 
        uint     excessAmount;              
    }
    address  public offerWinAddress; 
    address  private owner;
    enum Estado{ Activa, Cerrada, Pausada
    }    
    Estado public estado;
    address[] private offerAddresses; //Lista de direcciones ofertantes para poder recorrerlas y mostrar todas las ofertas
    mapping(address => Offer) private offers; //Mapeo una direccion a una oferta con la estructura de Offer    

    //Fin Variables Entorno


    constructor () {
        FloorValue = 10 gwei;
        StartDate = block.timestamp;
        Timeframe = StartDate + 7 days;        
        owner = msg.sender;
        estado = Estado.Activa;        
    }

    //Inicio Eventos
    event NewBid(address indexed bidder, uint amount);
    event EndAuction (string text);
    event AuctionExtended(uint newTimeframe);
    event Withdraw (address indexed bidder, uint amount);
    //Fin Eventos

    //Inicio modificadores
    modifier withinWithdrawalWindow(uint _deadline) {   //agrega un limite de tiempo al retiro
        require(block.timestamp <= _deadline, "El tiempo de retiro manual ha expirado");
        _;
    }
    modifier onlyAfterAuction() { //Solo si termino la subasta
        require(block.timestamp >= Timeframe, "La subasta sigue vigente");
    _;
    }
    modifier onlyOwner() { 
        require(msg.sender == owner, "Usted no tiene permisos");
        _;
    }

    modifier onlyWinner (){
        require(msg.sender == offerWinAddress, "No gano la subasta no puede claimear el item subastado");
        _;
     }
    modifier onlyNotWinner (){
        require(msg.sender != offerWinAddress, "Gano la subasta no puede retirar la oferta");
        _;
     }
     modifier onlyActive (){        
        require(estado == Estado.Activa, "La subasta ha terminado o se encuentra pausada");  //Valido si esta activa la subasta
        _;
     }

     modifier extendAuctionIfNeeded() {     
        if (block.timestamp >= Timeframe - 10 minutes) {
            Timeframe += 10 minutes;  
            emit AuctionExtended(Timeframe);  
        }
        _;
    }
    //Fin modificadores

    //Inicio funciones
    function manualWithdraw() external  onlyAfterAuction withinWithdrawalWindow(Timeframe + 30 days) onlyNotWinner {
        uint amount = offers[msg.sender].offerAmount;
        require(amount > 0, "No tienes monto a retirar");
        offers[msg.sender].offerAmount = 0;  
        uint refundAmount = amount * 98 / 100;
        payable(msg.sender).transfer(refundAmount);
        emit Withdraw(msg.sender,refundAmount);
    }

    function bulkWithdraw() internal onlyAfterAuction onlyOwner  { //devuelvo los retiros sin reclamar pasado los x dias definidos para retiro manual cobrando una mayor comision
        for (uint i = 0; i < offerAddresses.length; i++) {
            address addresReturn = offerAddresses[i];
            uint amount = offers[addresReturn].offerAmount;        
            if (amount > 0 && offerWinAddress != addresReturn) {
                offers[addresReturn].offerAmount = 0;  
                uint refundAmount = amount * 90 / 100; 
                payable(addresReturn).transfer(refundAmount);
            }
        }
        emit EndAuction("La subasta termino devuelvo retiro sin reclamar.");
    }


    function AuctionEnded() external onlyOwner {
        require(block.timestamp >= Timeframe, "La subasta sigue vigente");       
        estado = Estado.Cerrada;
        emit EndAuction("La subasta ha terminado");
    }     
     
    function setOffer () external payable extendAuctionIfNeeded onlyActive {              
      require(msg.sender != owner, "El propietario no puede ofertar en su propia subasta");
      if (offers[msg.sender].offerAmount == 0) {    //Verifico si ya realizo una oferta esa address
            offerAddresses.push(msg.sender);
        } else {
        //  Me fijo si ya esta ganando la subasta o si es el owner
        require(msg.sender != offerWinAddress , "Ya tienes la oferta mas alta");
      }
      require(msg.value >= offerWinAmount *105/100, "La oferta debe ser superior al menos en 5%");     //Verifico si la oferta es valida
      offers[msg.sender] = Offer({
            date: block.timestamp,
            offerAmount: msg.value,
            excessAmount: offers[msg.sender].offerAmount > 0 ? offers[msg.sender].excessAmount + offers[msg.sender].offerAmount : 0
        });       //Registro la oferta, y actualizo el excess si ya realizo oferta para que pueda retirar
        offerWinAmount = msg.value;   //Actualizo la oferta ganadora y la address podria hacerlo en una funcion aparte
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
        uint amount = offers[msg.sender].excessAmount;
        require(amount>0,"No tiene suficiente saldo para retirar");
        offers[msg.sender].excessAmount = 0;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender,amount);
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

    function claimItem() external onlyWinner onlyAfterAuction {
        require(estado == Estado.Cerrada, "La subasta no ha finalizado");    
        // Aca se haria la transferencia de ownership del item en cuestion

        emit EndAuction("El ganador reclamo el item");
    }
    function finalizeWithdrawals() external  onlyOwner onlyAfterAuction  {
        require(block.timestamp > Timeframe + 30 days, "Todavia esta habilitado el retiro manual");
        bulkWithdraw(); 
    }
    //Fin funciones
}