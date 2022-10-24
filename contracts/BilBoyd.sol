pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Car is ERC721 {
    uint256 public tokenCounter;
    address minterAddress;
    uint monthlyQuota;
    mapping(uint256 => CarInfo) public cars;

    struct CarInfo {
        string model;
        string colour;
        uint256 year;
        uint256 originalValue;
        address mintedBy;
    }

    constructor () public ERC721("Car", "CAR") {
        tokenCounter = 0;
    }
    
    function mint(address _to, string memory _model, string memory _colour, uint256 _year, uint256 _originalValue, address _mintedBy) external onlyOwner returns (uint256) {
        cars[tokenCounter] = CarInfo(_model, _colour, _year, _originalValue, _mintedBy);
        uint256 newTokenCounter = tokenCounter;
        _safeMint(_to, newTokenId);
        tokenCounter = tokenCounter + 1;
        return newTokenId;
    }

    function computeMonthlyQuota(uint256 _originalValue, uint256 _mileage, uint256 _posessionLicense, uint256 _mileageCap, uint256 _contractDuration) public returns (uint256) {
        monthlyQuota = (_originalValue + _mileageCap)/(_mileage + _posessionLicense + _contractDuration) * 1/25;
        return monthlyQuota;
    }
}