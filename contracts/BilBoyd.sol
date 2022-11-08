// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
 
contract BilBoyd is ERC721, Ownable {
    uint256 public tokenId;
    //address bilboydAddress;
    address customer;
    mapping(uint256 => leaseContract) public leaseInfoMapping;
    mapping(uint256 => car) public cars;
    mapping(uint256 => price) public prices;
 
   struct leaseContract {
       uint256 contractId;
       uint256 mileage;
       uint256 posessionLicense;
       uint256 mileageCap;
       uint256 contractDuration;
       address bilboydAddress;
       address renterAddress;
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
       address _bilboydAddress,
       address _renterAddress,
       uint256 _tokenId,
       uint _originalValue) public payable {
            setMonthlyQuota(_originalValue, _mileage, _posessionLicense, _mileageCap, _contractDuration, _tokenId);
            leaseInfoMapping[_contractId] = leaseContract(_contractId, _mileage, _posessionLicense, _mileageCap,
            _contractDuration, _bilboydAddress, _renterAddress, prices[_tokenId].price);
            checkBalance(_tokenId);
            customer = payable(msg.sender);
            require(msg.value == 4 * (prices[_tokenId].price), "Invalid value");
            payable(leaseInfoMapping[_contractId].bilboydAddress).transfer(msg.value);

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

 
   function monthlyPayment(uint256 _tokenId, uint256 _contractId) public payable {
        checkBalance(_tokenId);
        customer = payable(msg.sender);
        require(msg.value == (prices[_tokenId].price), "Invalid value");
        payable(leaseInfoMapping[_contractId].bilboydAddress).transfer(msg.value);
   }

    //Kan seller og buyer sjekkes mot msg.sender?
   modifier onlyBuyer(uint256 _id) {
       require(msg.sender == leaseInfoMapping[_id].renterAddress, "Only the buyer can call this.");
       _;
   }

   modifier onlySeller(uint256 _id) {
       require(msg.sender == leaseInfoMapping[_id].bilboydAddress, "Only the seller can call this.");
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
            //
            setMonthlyQuota(cars[_tokenId].originalValue, _mileage, _posessionLicense, _mileageCap, 
            leaseInfoMapping[_contractId].contractDuration + _newDuration, _tokenId);
            leaseInfoMapping[_contractId].contractDuration += _newDuration;
            leaseInfoMapping[_contractId].mileage = _mileage;
            leaseInfoMapping[_contractId].posessionLicense = _posessionLicense;
            leaseInfoMapping[_contractId].mileageCap = _mileageCap;
    }




}
