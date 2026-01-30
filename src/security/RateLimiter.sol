// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RateLimiter {
    struct RateLimit {
        uint256 maxRequests;
        uint256 windowSize;
        uint256 currentCount;
        uint256 windowStart;
    }

    mapping(address => RateLimit) public userLimits;
    mapping(address => mapping(string => RateLimit)) public actionLimits;

    function setRateLimit(uint256 maxRequests, uint256 windowSize) external {
        userLimits[msg.sender] = RateLimit({
            maxRequests: maxRequests,
            windowSize: windowSize,
            currentCount: 0,
            windowStart: block.timestamp
        });
    }

    function checkRateLimit(address user) external returns (bool allowed) {
        RateLimit storage limit = userLimits[user];
        
        if (block.timestamp >= limit.windowStart + limit.windowSize) {
            limit.currentCount = 0;
            limit.windowStart = block.timestamp;
        }
        
        if (limit.currentCount >= limit.maxRequests) {
            return false;
        }
        
        limit.currentCount++;
        return true;
    }

    function checkActionLimit(address user, string memory action) external returns (bool allowed) {
        RateLimit storage limit = actionLimits[user][action];
        
        if (limit.maxRequests == 0) return true; // No limit set
        
        if (block.timestamp >= limit.windowStart + limit.windowSize) {
            limit.currentCount = 0;
            limit.windowStart = block.timestamp;
        }
        
        if (limit.currentCount >= limit.maxRequests) {
            return false;
        }
        
        limit.currentCount++;
        return true;
    }
}
