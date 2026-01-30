// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract QueueManager {
    struct QueueItem {
        bytes32 id;
        bytes data;
        uint256 priority;
        uint256 timestamp;
        bool processed;
        address submitter;
    }

    mapping(string => QueueItem[]) public queues;
    mapping(string => uint256) public queueSizes;
    mapping(bytes32 => uint256) public itemIndices;

    event ItemQueued(string indexed queueName, bytes32 indexed itemId, uint256 priority);
    event ItemProcessed(string indexed queueName, bytes32 indexed itemId);

    function enqueue(
        string memory queueName,
        bytes memory data,
        uint256 priority
    ) external returns (bytes32 itemId) {
        itemId = keccak256(abi.encodePacked(msg.sender, data, block.timestamp));
        
        QueueItem memory item = QueueItem({
            id: itemId,
            data: data,
            priority: priority,
            timestamp: block.timestamp,
            processed: false,
            submitter: msg.sender
        });

        queues[queueName].push(item);
        queueSizes[queueName]++;
        itemIndices[itemId] = queues[queueName].length - 1;

        // Sort by priority (higher priority first)
        _sortQueue(queueName);

        emit ItemQueued(queueName, itemId, priority);
    }

    function dequeue(string memory queueName) external returns (QueueItem memory item) {
        require(queueSizes[queueName] > 0, "Queue is empty");
        
        item = queues[queueName][0];
        item.processed = true;
        
        // Remove first item and shift array
        for (uint256 i = 0; i < queues[queueName].length - 1; i++) {
            queues[queueName][i] = queues[queueName][i + 1];
        }
        queues[queueName].pop();
        queueSizes[queueName]--;

        emit ItemProcessed(queueName, item.id);
    }

    function _sortQueue(string memory queueName) internal {
        QueueItem[] storage queue = queues[queueName];
        
        // Simple bubble sort by priority (descending)
        for (uint256 i = 0; i < queue.length; i++) {
            for (uint256 j = i + 1; j < queue.length; j++) {
                if (queue[i].priority < queue[j].priority) {
                    QueueItem memory temp = queue[i];
                    queue[i] = queue[j];
                    queue[j] = temp;
                }
            }
        }
    }

    function getQueueSize(string memory queueName) external view returns (uint256) {
        return queueSizes[queueName];
    }

    function peekQueue(string memory queueName) external view returns (QueueItem memory) {
        require(queueSizes[queueName] > 0, "Queue is empty");
        return queues[queueName][0];
    }
}
