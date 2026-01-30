// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionAlerts {
    struct Alert {
        string message;
        uint256 severity;
        uint256 timestamp;
        bool acknowledged;
    }

    mapping(address => Alert[]) public userAlerts;
    
    event AlertCreated(address indexed user, string message, uint256 severity);

    function createAlert(address user, string memory message, uint256 severity) external {
        userAlerts[user].push(Alert({
            message: message,
            severity: severity,
            timestamp: block.timestamp,
            acknowledged: false
        }));

        emit AlertCreated(user, message, severity);
    }

    function acknowledgeAlert(uint256 alertIndex) external {
        require(alertIndex < userAlerts[msg.sender].length, "Invalid alert");
        userAlerts[msg.sender][alertIndex].acknowledged = true;
    }
}
