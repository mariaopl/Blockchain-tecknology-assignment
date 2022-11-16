// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
 
contract BilBoyd is ERC721, Ownable {
    uint256 public tokenId;
    uint256 public contractId;
    uint256 public customerId;
    address bilboydAddress;
    mapping(uint256 => leaseContract) public leaseInfoMapping;
    mapping(uint256 => car) public cars;
    mapping(uint256 => price) public prices;
    mapping(uint256 => customer) public customers;
    mapping(uint256 => activeContract) public activeContracts;

    //State is used to ensure fair exchange
    enum State { Created , Locked , Inactive }
    State public state;
 
   struct leaseContract {
       uint256 mileage;
       uint256 posessionLicense;
       uint256 mileageCap;
       uint256 contractDuration;
       uint256 monthlyQuota;
       address customerAddress;
   }

   struct activeContract {
       uint256 contractId;
   }

   struct customer {
       address customerAddress;
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
       bilboydAddress = msg.sender;
       tokenId = 0;
       contractId = 0;
   }
 
    //Lease function sets values for the contract, sets the monthlyQuota. It requires the state to be locked to seal the deal.
    //Therefore it checks that the state is Locked (that the renter has accepted the offer) before it makes the fair exchange
    //The renter sends the payment and BilBoyd adds the contract to the leaseInfoMapping.
    //The available field in the car struct is set to false, since it's not avaialble anymore when its leased out
    function lease(
        uint256 _mileage,
        uint256 _posessionLicense,
        uint256 _mileageCap,
        uint256 _contractDuration,
        uint256 _tokenId,
        uint _originalValue,
        uint256 _customerId)
        public payable inState(State.Locked) {
            setMonthlyQuota(_originalValue, _mileage, _posessionLicense, _mileageCap, _contractDuration, _tokenId);
            require(checkBalance(_tokenId, _customerId) == true, "Not enough ether");
            payable(customers[_customerId].customerAddress);
            require(msg.value == 4 * (prices[_tokenId].price), "Invalid value");
            payable(bilboydAddress).transfer(msg.value);
            leaseInfoMapping[contractId] = leaseContract(_mileage, _posessionLicense, _mileageCap,
            _contractDuration, prices[_tokenId].price, customers[_customerId].customerAddress);
            uint256 newContractId = contractId;
            contractId = newContractId + 1;
            cars[_tokenId].available = false;
    }

    //The idea is that a customer enters the BilBoyd shop and registers as a customer before starting the leasing negotiation or sale
    //BilBoyd keeps a mapping of all customers to keep track for future lease extensions or new deals
    function addCustomer(address _customerAddress) external onlyOwner {
        customers[customerId] = customer(_customerAddress);
        uint256 newCustomerId = customerId;
        customerId = newCustomerId + 1;
    }

    //This function mints a new car with these variables. It also creates a tokenID that is stored in a mapping to keep track of all cars
   function mint(
       string memory _model, 
       string memory _colour, 
       uint256 _year, 
       uint256 _originalValue) 
       external onlyOwner returns (uint256) { 
       cars[tokenId] = car(true, _colour, _year, _model, _originalValue);
       uint256 newTokenId = tokenId;
       _safeMint(bilboydAddress, newTokenId);
       tokenId = tokenId + 1;
       return newTokenId;
   }

    //This function calculates the monthly quota without using any gas. The actual calculation of the monthly quota is arbitrary
    function setMonthlyQuota(
        uint256 _originalValue, 
        uint256 _mileage, 
        uint256 _posessionLicense, 
        uint256 _mileageCap, 
        uint256 _contractDuration,
        uint256 _tokenId) 
        public {
        uint256 monthlyQuota = _originalValue + _posessionLicense * 3 + _mileageCap - _mileage * 200 - _contractDuration * 200;
        prices[_tokenId] = price(monthlyQuota);
   }

    //This function returns the monthly quota for a given token id
    function getMonthlyQuota(uint256 _tokenId) external view returns (uint256 _cost){
        _cost = prices[_tokenId].price;
        return _cost;
    }

    //This function gets the balance of the customer to use in the next function
    function getBalance(uint256 _customerId) public view returns (uint256) {
        return customers[_customerId].customerAddress.balance;
    }

    //This function checks the balance of the customer to give BilBoyd security in that the customer is able to pay
    function checkBalance(uint256 _tokenId, uint256 _customerId) public view returns (bool) {
        if (getBalance(_customerId) >= 4 * (prices[_tokenId].price)) {
            return true;
        }
        else {
            return false;
        }
   }

    //This function ensures fair exchange by requiring the customer to accept the offer before the exchange happends
    function confirmPurchase(uint256 _customerId) public onlyOwner inState(State.Created) {
        customers[_customerId].customerAddress = msg.sender;
        state = State.Locked;
    }
 
    //This function transfers the motnhly value to BilBoyd
    function monthlyPayment(uint256 _tokenId, uint256 _customerId) public payable {
        checkBalance(_tokenId, _customerId);
        customers[_customerId].customerAddress;
        require(msg.value == (prices[_tokenId].price), "Invalid value");
        payable(bilboydAddress).transfer(msg.value);
    }

    //This modifier checks that the state is correct
    modifier inState(State _state) {
        require( state == _state , "Invalid state.");
        _;
    }

    //This modifier checks if the given condition id correct
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    //This function is used if the customer wishes to end terminate the lease at the end of the leaseperiod
    //The available attribute is set to true since the car is now available
    function terminateContract(uint256 _contractId, uint256 _tokenId) public {
        _burn(_contractId);
        cars[_tokenId].available = true;
    }

    //This function is used if the customer wants to extend the lease at the end of the lease period
    //The function changes variables that has changed since the time of the last leases beginning
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
