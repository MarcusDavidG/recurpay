// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TaskScheduler {
    enum TaskStatus { PENDING, RUNNING, COMPLETED, FAILED, CANCELLED }

    struct Task {
        bytes32 id;
        address creator;
        bytes payload;
        uint256 executeAt;
        uint256 interval;
        uint256 maxExecutions;
        uint256 executionCount;
        TaskStatus status;
        address executor;
    }

    mapping(bytes32 => Task) public tasks;
    mapping(uint256 => bytes32[]) public scheduledTasks; // timestamp => task IDs
    mapping(address => bytes32[]) public creatorTasks;
    
    bytes32[] public allTasks;

    event TaskScheduled(bytes32 indexed taskId, address creator, uint256 executeAt);
    event TaskExecuted(bytes32 indexed taskId, address executor, bool success);
    event TaskCancelled(bytes32 indexed taskId);

    function scheduleTask(
        bytes memory payload,
        uint256 executeAt,
        uint256 interval,
        uint256 maxExecutions
    ) external returns (bytes32 taskId) {
        require(executeAt > block.timestamp, "Execute time must be in future");
        
        taskId = keccak256(abi.encodePacked(msg.sender, payload, block.timestamp));
        
        tasks[taskId] = Task({
            id: taskId,
            creator: msg.sender,
            payload: payload,
            executeAt: executeAt,
            interval: interval,
            maxExecutions: maxExecutions,
            executionCount: 0,
            status: TaskStatus.PENDING,
            executor: address(0)
        });

        uint256 timeSlot = executeAt / 1 hours; // Hour-based slots
        scheduledTasks[timeSlot].push(taskId);
        creatorTasks[msg.sender].push(taskId);
        allTasks.push(taskId);

        emit TaskScheduled(taskId, msg.sender, executeAt);
    }

    function executeTask(bytes32 taskId) external returns (bool success) {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.PENDING, "Task not pending");
        require(block.timestamp >= task.executeAt, "Not yet time to execute");

        task.status = TaskStatus.RUNNING;
        task.executor = msg.sender;

        // Simulate task execution
        success = executeTaskLogic(task.payload);
        
        task.executionCount++;

        if (success) {
            if (task.interval > 0 && task.executionCount < task.maxExecutions) {
                // Reschedule recurring task
                task.executeAt = block.timestamp + task.interval;
                task.status = TaskStatus.PENDING;
                
                uint256 newTimeSlot = task.executeAt / 1 hours;
                scheduledTasks[newTimeSlot].push(taskId);
            } else {
                task.status = TaskStatus.COMPLETED;
            }
        } else {
            task.status = TaskStatus.FAILED;
        }

        emit TaskExecuted(taskId, msg.sender, success);
    }

    function executeTaskLogic(bytes memory payload) internal pure returns (bool) {
        // Simplified execution logic
        return payload.length > 0;
    }

    function cancelTask(bytes32 taskId) external {
        Task storage task = tasks[taskId];
        require(task.creator == msg.sender, "Not task creator");
        require(task.status == TaskStatus.PENDING, "Cannot cancel");

        task.status = TaskStatus.CANCELLED;
        emit TaskCancelled(taskId);
    }

    function getTasksForTimeSlot(uint256 timeSlot) external view returns (bytes32[] memory) {
        return scheduledTasks[timeSlot];
    }

    function getCreatorTasks(address creator) external view returns (bytes32[] memory) {
        return creatorTasks[creator];
    }

    function getExecutableTasks() external view returns (bytes32[] memory executable) {
        uint256 currentTimeSlot = block.timestamp / 1 hours;
        uint256 executableCount = 0;

        // Count executable tasks
        for (uint256 i = 0; i <= currentTimeSlot; i++) {
            bytes32[] memory slotTasks = scheduledTasks[i];
            for (uint256 j = 0; j < slotTasks.length; j++) {
                Task memory task = tasks[slotTasks[j]];
                if (task.status == TaskStatus.PENDING && block.timestamp >= task.executeAt) {
                    executableCount++;
                }
            }
        }

        // Collect executable tasks
        executable = new bytes32[](executableCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i <= currentTimeSlot; i++) {
            bytes32[] memory slotTasks = scheduledTasks[i];
            for (uint256 j = 0; j < slotTasks.length; j++) {
                Task memory task = tasks[slotTasks[j]];
                if (task.status == TaskStatus.PENDING && block.timestamp >= task.executeAt) {
                    executable[index] = slotTasks[j];
                    index++;
                }
            }
        }
    }
}
