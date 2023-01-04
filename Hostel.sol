pragma solidity ^0.5.16;

contract Hostel{
    address payable tenant;
    address payable landlord;

    uint public noOfRooms = 0;
    uint public noOfAgreement = 0;
    uint public noOfRent = 0;

    struct Room{
        uint roomId;
        uint agreementId;
        string roomName;
        string roomAddress;
        uint rentPerMonth;
        uint securityDeposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address payable currentTenant;
    }

    mapping(uint => Room) public RoomByNo;

    struct RoomAgreement{
        uint roomId;
        uint agreementId;
        string RoomName;
        string RoomAddress;
        uint rentPerMonth;
        uint securityDeposit;
        uint lockInPeriod;
        uint timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }

    mapping(uint => RoomAgreement) public RoomAgreementByNo;

    struct Rent{
        uint rentNo;
        uint roomId;
        uint agreementId;
        string RoomName;
        string RoomAddress;
        uint rentPerMonth;
        uint timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }

    mapping(uint => Rent) public RentByNo;

    modifier onlyLandlord(uint _index)
    {
        require(msg.sender == RoomByNo[_index].landlord, "Only LANDLORD can access this");
        _;
    }

    modifier notLandlord(uint _index)
    {
        require(msg.sender != RoomByNo[_index].landlord, "Only TENANT can access this");
        _;
    }

    modifier OnlyWhileVacant(uint _index)
    {
        require(RoomByNo[_index].vacant == true, "Room is currently OCCUPIED.");
        _;
    }

    modifier enoughRent(uint _index){
        require(msg.value >= uint(RoomByNo[_index].rentPerMonth), "Not enough Ether in your wallet");
        _;
    }

    modifier enoughAgreementfee(uint _index){
        require(msg.value >= uint(uint(RoomByNo[_index].rentPerMonth) + uint(RoomByNo[_index].securityDeposit)),
        "Not enough Ether in your wallet");
        _;
    }

    modifier sameTenant(uint _index){
        require(msg.sender == RoomByNo[_index].currentTenant, "No previous agreement found qith you & landlord");
        _;
    }

    modifier AgreementTimesLeft(uint _index){
        uint _AgreementNo = RoomByNo[_index].agreementId;
        uint time = RoomAgreementByNo[_AgreementNo].timestamp + RoomAgreementByNo [_AgreementNo].lockInPeriod;
        require(block.timestamp < time, "Agreement already Ended");
        _;
    }

    modifier AgreementTimesUp(uint _index){
        uint _AgreementNo = RoomByNo[_index].agreementId;
        uint time = RoomAgreementByNo[_AgreementNo].timestamp + RoomAgreementByNo[_AgreementNo].lockInPeriod;
        require(block.timestamp > time, "Time is left for contract to end");
        _;
    }

    modifier RentTimesUp(uint _index){
        uint time = RoomByNo[_index].timestamp + 30 days;
        require(block.timestamp >= time, "Time left to pay RENT");
        _;
    }

    function addRoom(string memory _roomName, string memory _roomAddress, uint _rentCost, uint _securityDeposit)
    public{
        require(msg.sender != address(0));
        noOfRooms ++;
        bool _vacancy = true;
        RoomByNo[noOfRooms] = Room(noOfRooms, 0, _roomName, _roomAddress, _rentCost, _securityDeposit, 0, _vacancy, msg.sender, address(0));
    }

    function signAgreement(uint _index) 
    public payable notLandlord(_index) enoughAgreementfee(_index) OnlyWhileVacant(_index){
        require(msg.sender !=address(0));
        address payable _landlord = RoomByNo[_index].landlord;
        uint totalFee = RoomByNo[_index].rentPerMonth + RoomByNo[_index].securityDeposit;
        _landlord.transfer(totalFee);
        noOfAgreement++;
        RoomByNo[_index].currentTenant = msg.sender;
        RoomByNo[_index].vacant = false;
        RoomByNo[_index].timestamp = block.timestamp;
        RoomByNo[_index].agreementId = noOfAgreement;
        RoomAgreementByNo[noOfAgreement] = RoomAgreement(_index, noOfAgreement, RoomByNo[_index].roomName, RoomByNo[_index].roomAddress, RoomByNo[_index].rentPerMonth,
        RoomByNo[_index].securityDeposit, 365 days, block.timestamp, msg.sender, _landlord);
        noOfRent ++;
        RentByNo[noOfRent] = Rent(noOfRent,_index, noOfAgreement, RoomByNo[_index].roomName, RoomByNo[_index].roomAddress, RoomByNo[_index].rentPerMonth, now, msg.sender, _landlord);
    }

    function payRent(uint _index) 
    public payable sameTenant(_index) RentTimesUp(_index) enoughRent(_index)
    {
        require(msg.sender != address(0));
        address payable _landlord = RoomByNo[_index].landlord;
        uint _rent = RoomByNo[_index].rentPerMonth;
        _landlord.transfer(_rent);
        RoomByNo[_index].currentTenant = msg.sender;
        RoomByNo[_index].vacant = false;
        noOfRent ++;
        RentByNo[noOfRent] = Rent(noOfRent, _index, RoomByNo[_index].agreementId, RoomByNo[_index].roomName, RoomByNo[_index].roomAddress, _rent, now, msg.sender, RoomByNo[_index].landlord);
    } 

    function agreementCompleted(uint _index)
    public payable onlyLandlord(_index) AgreementTimesUp(_index){
        require(msg.sender != address(0));
        require(RoomByNo[_index].vacant == false, "Room is currently OCCUPIED");
        RoomByNo[_index].vacant = true;
        address payable _tenant = RoomByNo[_index].currentTenant;
        uint _securityDeposit = RoomByNo[_index].securityDeposit;
        _tenant.transfer(_securityDeposit);
    }

    function agreementTerminated(uint _index)
    public onlyLandlord(_index) AgreementTimesLeft(_index){
        require(msg.sender != address(0));
        RoomByNo[_index].vacant = true;
    }
}
