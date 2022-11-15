// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
 
contract BilBoyd is ERC721, Ownable {
    uint256 public tokenId;
    address bilboydAddress;
    address customerAddress;
    mapping(uint256 => leaseContract) public leaseInfoMapping;
    mapping(uint256 => car) public cars;
    mapping(uint256 => price) public prices;

    enum State { Created , Locked , Inactive }
    State public state;
 
   struct leaseContract {
       uint256 contractId;
       uint256 mileage;
       uint256 posessionLicense;
       uint256 mileageCap;
       uint256 contractDuration;
       uint256 monthlyQuota;
   }

    struct price {
        uint256 price;
    }
   
   struct car {
       bool available;
       string colour;
       uint256 yearOfMatriculation;
       string model;
       uint256 originalValue;
   }

   constructor() ERC721("Car", "CAR") {
       //bilboydAddress = msg.sender;
       tokenId = 0;
   }
 
   function lease(uint256 _contractId,
       uint256 _mileage,
       uint256 _posessionLicense,
       uint256 _mileageCap,
       uint256 _contractDuration,
       uint256 _tokenId,
       uint _originalValue) public payable {
            setMonthlyQuota(_originalValue, _mileage, _posessionLicense, _mileageCap, _contractDuration, _tokenId);
            leaseInfoMapping[_contractId] = leaseContract(_contractId, _mileage, _posessionLicense, _mileageCap,
            _contractDuration, prices[_tokenId].price);
            checkBalance(_tokenId);
            customerAddress = payable(msg.sender);
            require(msg.value == 4 * (prices[_tokenId].price), "Invalid value");
            payable(bilboydAddress).transfer(msg.value);

    }
 
   function mint(
       address _to, 
       string memory _model, 
       string memory _colour, 
       uint256 _year, 
       uint256 _originalValue,
       bool _available) 
       external onlyOwner returns (uint256) { 
       cars[tokenId] = car(_available, _colour, _year, _model, _originalValue);
       uint256 newTokenId = tokenId;
       _safeMint(_to, newTokenId);
       tokenId = tokenId + 1;
       return newTokenId;
   }

    
    function setMonthlyQuota(
        uint256 _originalValue, 
        uint256 _mileage, 
        uint256 _posessionLicense, 
        uint256 _mileageCap, 
        uint256 _contractDuration,
        uint256 _tokenId) 
        public {
        uint256 monthlyQuota = (_originalValue + _mileageCap) + (_mileage + _posessionLicense + _contractDuration);
        prices[_tokenId] = price(monthlyQuota);
   }

    function getMonthlyQuota(uint256 _tokenId) external view returns (uint256 _cost){
        _cost = prices[_tokenId].price;
        return _cost;
    }

    function getBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

      function checkBalance(uint256 _tokenId) public view returns (bool) {
       require(getBalance() >= 4 * (prices[_tokenId].price), "The renter does not have enough funds.");
   }

   function confirmPurchase(uint256 _tokenId) public inState(State.Created) condition(msg.value == (prices[_tokenId].price)) payable {
        customerAddress = msg.sender;
        state = State.Locked;
    }

    function confirmReceived(uint256 _tokenId) public onlyBuyer inState(State.Locked) payable {
        state = State.Inactive;
        payable(customerAddress).transfer(prices[_tokenId].price);
        payable(bilboydAddress).transfer(address(this).balance);
    }

 
   function monthlyPayment(uint256 _tokenId) public payable {
        checkBalance(_tokenId);
        customerAddress = payable(msg.sender);
        require(msg.value == (prices[_tokenId].price), "Invalid value");
        payable(bilboydAddress).transfer(msg.value);
   }

    //Kan seller og buyer sjekkes mot msg.sender?
   modifier onlyBuyer() {
       require(msg.sender == customerAddress, "Only the buyer can call this.");
       _;
   }

   modifier onlySeller() {
       require(msg.sender == bilboydAddress, "Only the seller can call this.");
       _;
   }

   modifier inState(State _state) {
        require( state == _state , "Invalid state.");
        _;
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    function terminateContract(uint256 _contractId, uint256 _tokenId) public {
        _burn(_contractId);
        cars[_tokenId].available = true;
    }

    function extendLease(uint256 _contractId, uint256 _newDuration,
        uint256 _mileage, 
        uint256 _posessionLicense, 
        uint256 _mileageCap, 
        uint256 _tokenId) public {
            setMonthlyQuota(cars[_tokenId].originalValue, _mileage, _posessionLicense, _mileageCap, 
            leaseInfoMapping[_contractId].contractDuration + _newDuration, _tokenId);
            leaseInfoMapping[_contractId].contractDuration += _newDuration;
            leaseInfoMapping[_contractId].mileage = _mileage;
            leaseInfoMapping[_contractId].posessionLicense = _posessionLicense;
            leaseInfoMapping[_contractId].mileageCap = _mileageCap;
    }




}
