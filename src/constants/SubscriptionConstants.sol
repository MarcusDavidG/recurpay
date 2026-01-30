// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionConstants {
    // Time constants
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_WEEK = 604800;
    uint256 public constant SECONDS_PER_MONTH = 2592000;
    uint256 public constant SECONDS_PER_YEAR = 31536000;

    // Percentage constants (basis points)
    uint256 public constant MAX_FEE_PERCENTAGE = 1000; // 10%
    uint256 public constant DEFAULT_LATE_FEE = 500; // 5%
    uint256 public constant MAX_DISCOUNT = 5000; // 50%
    uint256 public constant BASIS_POINTS = 10000; // 100%

    // Subscription limits
    uint256 public constant MIN_SUBSCRIPTION_PRICE = 0.001 ether;
    uint256 public constant MAX_SUBSCRIPTION_PRICE = 1000 ether;
    uint256 public constant MIN_BILLING_PERIOD = 1 days;
    uint256 public constant MAX_BILLING_PERIOD = 365 days;
    uint256 public constant DEFAULT_GRACE_PERIOD = 3 days;
    uint256 public constant MAX_GRACE_PERIOD = 30 days;

    // System limits
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant MAX_RETRY_ATTEMPTS = 5;
    uint256 public constant DEFAULT_TIMEOUT = 1 hours;

    // Status codes
    uint8 public constant STATUS_ACTIVE = 1;
    uint8 public constant STATUS_PAUSED = 2;
    uint8 public constant STATUS_CANCELLED = 3;
    uint8 public constant STATUS_EXPIRED = 4;
    uint8 public constant STATUS_GRACE_PERIOD = 5;

    // Error codes
    string public constant ERROR_INSUFFICIENT_BALANCE = "Insufficient balance";
    string public constant ERROR_INVALID_AMOUNT = "Invalid amount";
    string public constant ERROR_SUBSCRIPTION_NOT_FOUND = "Subscription not found";
    string public constant ERROR_UNAUTHORIZED = "Unauthorized";
    string public constant ERROR_ALREADY_EXISTS = "Already exists";
    string public constant ERROR_EXPIRED = "Expired";
    string public constant ERROR_PAUSED = "Paused";
    string public constant ERROR_INVALID_PERIOD = "Invalid period";

    function getTimeConstant(string memory name) external pure returns (uint256) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        
        if (nameHash == keccak256("DAY")) return SECONDS_PER_DAY;
        if (nameHash == keccak256("WEEK")) return SECONDS_PER_WEEK;
        if (nameHash == keccak256("MONTH")) return SECONDS_PER_MONTH;
        if (nameHash == keccak256("YEAR")) return SECONDS_PER_YEAR;
        
        return 0;
    }

    function getPercentageConstant(string memory name) external pure returns (uint256) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        
        if (nameHash == keccak256("MAX_FEE")) return MAX_FEE_PERCENTAGE;
        if (nameHash == keccak256("LATE_FEE")) return DEFAULT_LATE_FEE;
        if (nameHash == keccak256("MAX_DISCOUNT")) return MAX_DISCOUNT;
        if (nameHash == keccak256("BASIS_POINTS")) return BASIS_POINTS;
        
        return 0;
    }
}
