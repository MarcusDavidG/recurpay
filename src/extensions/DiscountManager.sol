// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DiscountManager {
    struct Discount {
        uint256 percentage;
        uint256 validUntil;
        uint256 maxUses;
        uint256 currentUses;
        bool active;
        string code;
    }

    mapping(bytes32 => Discount) public discounts;
    mapping(address => mapping(bytes32 => bool)) public userUsedDiscount;

    event DiscountCreated(bytes32 indexed discountId, string code, uint256 percentage);
    event DiscountUsed(bytes32 indexed discountId, address indexed user);

    function createDiscount(
        string memory code,
        uint256 percentage,
        uint256 validUntil,
        uint256 maxUses
    ) external returns (bytes32 discountId) {
        require(percentage <= 10000, "Invalid percentage");
        
        discountId = keccak256(abi.encodePacked(msg.sender, code, block.timestamp));
        
        discounts[discountId] = Discount({
            percentage: percentage,
            validUntil: validUntil,
            maxUses: maxUses,
            currentUses: 0,
            active: true,
            code: code
        });

        emit DiscountCreated(discountId, code, percentage);
    }

    function applyDiscount(bytes32 discountId, address user) external returns (uint256 discountAmount) {
        Discount storage discount = discounts[discountId];
        
        require(discount.active, "Discount not active");
        require(block.timestamp <= discount.validUntil, "Discount expired");
        require(discount.currentUses < discount.maxUses, "Discount limit reached");
        require(!userUsedDiscount[user][discountId], "User already used discount");

        discount.currentUses++;
        userUsedDiscount[user][discountId] = true;

        emit DiscountUsed(discountId, user);
        return discount.percentage;
    }

    function calculateDiscountedPrice(uint256 originalPrice, uint256 discountPercentage) 
        external 
        pure 
        returns (uint256) 
    {
        return originalPrice - (originalPrice * discountPercentage / 10000);
    }
}
