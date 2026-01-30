// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionLogger {
    struct LogEntry {
        uint256 level;
        string message;
        bytes data;
        uint256 timestamp;
        address sender;
    }

    LogEntry[] public logs;
    mapping(uint256 => uint256) public logCountByLevel;
    
    uint256 public constant DEBUG = 0;
    uint256 public constant INFO = 1;
    uint256 public constant WARN = 2;
    uint256 public constant ERROR = 3;

    event LogEmitted(uint256 level, string message, address sender);

    function log(uint256 level, string memory message, bytes memory data) external {
        logs.push(LogEntry({
            level: level,
            message: message,
            data: data,
            timestamp: block.timestamp,
            sender: msg.sender
        }));

        logCountByLevel[level]++;
        emit LogEmitted(level, message, msg.sender);
    }

    function debug(string memory message) external {
        this.log(DEBUG, message, "");
    }

    function info(string memory message) external {
        this.log(INFO, message, "");
    }

    function warn(string memory message) external {
        this.log(WARN, message, "");
    }

    function error(string memory message) external {
        this.log(ERROR, message, "");
    }

    function getLogCount() external view returns (uint256) {
        return logs.length;
    }

    function getLogsByLevel(uint256 level, uint256 limit) external view returns (LogEntry[] memory) {
        LogEntry[] memory result = new LogEntry[](limit);
        uint256 count = 0;
        
        for (uint256 i = logs.length; i > 0 && count < limit; i--) {
            if (logs[i-1].level == level) {
                result[count] = logs[i-1];
                count++;
            }
        }
        
        // Resize array to actual count
        assembly {
            mstore(result, count)
        }
        
        return result;
    }
}
