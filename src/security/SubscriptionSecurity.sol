// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionSecurity {
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public suspiciousActivity;
    
    uint256 public constant SUSPICIOUS_THRESHOLD = 10;

    event UserBlacklisted(address indexed user);
    event SuspiciousActivityDetected(address indexed user, uint256 level);

    function blacklistUser(address user) external {
        blacklisted[user] = true;
        emit UserBlacklisted(user);
    }

    function reportSuspiciousActivity(address user) external {
        suspiciousActivity[user]++;
        
        if (suspiciousActivity[user] >= SUSPICIOUS_THRESHOLD) {
            blacklisted[user] = true;
            emit UserBlacklisted(user);
        }
        
        emit SuspiciousActivityDetected(user, suspiciousActivity[user]);
    }

    function isUserSafe(address user) external view returns (bool) {
        return !blacklisted[user] && suspiciousActivity[user] < SUSPICIOUS_THRESHOLD;
    }

    function removeFromBlacklist(address user) external {
        blacklisted[user] = false;
        suspiciousActivity[user] = 0;
    }
}
