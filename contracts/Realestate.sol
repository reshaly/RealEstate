// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Realestate is ERC721Upgradeable, OwnableUpgradeable {
    uint tokenIdCounter;

    mapping(address => bool) public blackListed;
    mapping(uint => bool) public ordered;
    mapping(uint => Property) public idToProperty;

    event Order(address indexed owner, Property prop);
    event RemoveOrder(uint indexed tokenId, address indexed owner);
    event Purchase(uint indexed tokenId, address indexed buyer, uint price);

    struct Property {
        string addr;
        uint apartmentNumber;
        uint floor;
        uint roomsCount;
        uint area;
        uint price; // Price in Wei (1 ETH = 10^18 Wei)
    }

    constructor(string memory _name, string memory _symbol) {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
    }

    /**
     * @dev Order a property and optionally mint an NFT.
     * @param property - the apartment parameters
     * @param tokenId - unique token ID, calculated off-chain or in frontend
     */
    function order(Property memory property, uint tokenId) external {
        require(!blackListed[msg.sender], "Realestate: You are blacklisted");
        require(!ordered[tokenId], "Realestate: Property already ordered");

        if (_ownerOf(tokenId) == address(0)) {
            _safeMint(msg.sender, tokenId);
        }

        idToProperty[tokenId] = property;
        ordered[tokenId] = true;

        emit Order(msg.sender, property);
    }

    /**
     * @dev Remove the order for a property.
     */
    function remove_order(uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Realestate: Not authorized");
        require(ordered[tokenId], "Realestate: No order exists");

        ordered[tokenId] = false;
        emit RemoveOrder(tokenId, msg.sender);
    }

    /**
     * @dev Buy a property and transfer ownership.
     */
    function buy(uint tokenId) external payable {
        require(ordered[tokenId], "Realestate: Property not listed for sale");
        Property memory property = idToProperty[tokenId];
        require(msg.value == property.price, "Realestate: Incorrect price");

        address currentOwner = ownerOf(tokenId);
        require(currentOwner != address(0), "Realestate: Invalid owner");
        require(!blackListed[msg.sender], "Realestate: Buyer is blacklisted");

        // Transfer funds to the seller
        payable(currentOwner).transfer(msg.value);

        // Transfer the NFT to the buyer
        _transfer(currentOwner, msg.sender, tokenId);

        // Mark property as no longer ordered
        ordered[tokenId] = false;

        emit Purchase(tokenId, msg.sender, property.price);
    }

    /**
     * @dev Get details of a property.
     */
    function get_property(uint tokenId) external view returns (Property memory) {
        require(_exists(tokenId), "Realestate: Property does not exist");
        return idToProperty[tokenId];
    }

    /**
     * @dev Add an address to the blacklist.
     */
    function addToblackListed(address _addr) external onlyOwner {
        blackListed[_addr] = true;
    }

    /**
     * @dev Check if an address is blacklisted.
     */
    function isblackListed(address _addr) external view onlyOwner returns (bool) {
        return blackListed[_addr];
    }
}
