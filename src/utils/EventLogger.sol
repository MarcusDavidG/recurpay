// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EventLogger {
    struct LogEntry {
        address user;
        string eventType;
        bytes data;
        uint256 timestamp;
        bytes32 transactionHash;
    }

    mapping(bytes32 => LogEntry) public logs;
    mapping(address => bytes32[]) public userLogs;
    mapping(string => bytes32[]) public eventTypeLogs;
    
    uint256 public logCounter;

    event LogCreated(bytes32 indexed logId, address indexed user, string eventType);

    function logEvent(
        address user,
        string memory eventType,
        bytes memory data
    ) external returns (bytes32 logId) {
        logId = keccak256(abi.encodePacked(user, eventType, block.timestamp, logCounter++));
        
        logs[logId] = LogEntry({
            user: user,
            eventType: eventType,
            data: data,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1)
        });

        userLogs[user].push(logId);
        eventTypeLogs[eventType].push(logId);

        emit LogCreated(logId, user, eventType);
    }

    function getUserLogs(address user) external view returns (bytes32[] memory) {
        return userLogs[user];
    }

    function getEventTypeLogs(string memory eventType) external view returns (bytes32[] memory) {
        return eventTypeLogs[eventType];
    }
}
