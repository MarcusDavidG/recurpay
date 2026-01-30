// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MessageQueue {
    struct Message {
        bytes32 id;
        address sender;
        bytes payload;
        uint256 priority;
        uint256 timestamp;
        uint256 retryCount;
        bool processed;
    }

    mapping(bytes32 => Message) public messages;
    mapping(uint256 => bytes32[]) public priorityQueues;
    mapping(address => bytes32[]) public senderMessages;
    
    bytes32[] public allMessages;
    uint256 public constant MAX_RETRIES = 3;

    event MessageQueued(bytes32 indexed messageId, address sender, uint256 priority);
    event MessageProcessed(bytes32 indexed messageId, bool success);

    function queueMessage(bytes memory payload, uint256 priority) external returns (bytes32 messageId) {
        messageId = keccak256(abi.encodePacked(msg.sender, payload, block.timestamp));
        
        messages[messageId] = Message({
            id: messageId,
            sender: msg.sender,
            payload: payload,
            priority: priority,
            timestamp: block.timestamp,
            retryCount: 0,
            processed: false
        });

        priorityQueues[priority].push(messageId);
        senderMessages[msg.sender].push(messageId);
        allMessages.push(messageId);

        emit MessageQueued(messageId, msg.sender, priority);
    }

    function processNextMessage() external returns (bytes32 messageId, bool success) {
        // Process highest priority messages first
        for (uint256 priority = 10; priority > 0; priority--) {
            if (priorityQueues[priority].length > 0) {
                messageId = priorityQueues[priority][0];
                
                // Remove from priority queue
                for (uint256 i = 0; i < priorityQueues[priority].length - 1; i++) {
                    priorityQueues[priority][i] = priorityQueues[priority][i + 1];
                }
                priorityQueues[priority].pop();

                Message storage message = messages[messageId];
                
                // Simulate processing
                success = processMessage(message);
                
                if (success) {
                    message.processed = true;
                } else {
                    message.retryCount++;
                    if (message.retryCount < MAX_RETRIES) {
                        // Re-queue for retry
                        priorityQueues[message.priority].push(messageId);
                    }
                }

                emit MessageProcessed(messageId, success);
                return (messageId, success);
            }
        }

        return (bytes32(0), false);
    }

    function processMessage(Message memory message) internal pure returns (bool) {
        // Simplified processing logic
        return message.payload.length > 0;
    }

    function getQueueLength(uint256 priority) external view returns (uint256) {
        return priorityQueues[priority].length;
    }

    function getMessage(bytes32 messageId) external view returns (Message memory) {
        return messages[messageId];
    }

    function getSenderMessages(address sender) external view returns (bytes32[] memory) {
        return senderMessages[sender];
    }
}
