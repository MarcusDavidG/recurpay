// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionScheduler {
    struct ScheduledSubscription {
        address subscriber;
        address creator;
        uint256 subscriptionId;
        uint256 startDate;
        uint256 endDate;
        uint256 amount;
        bool executed;
        bool cancelled;
        string reason;
    }

    struct RecurringSchedule {
        uint256 interval; // in seconds
        uint256 nextExecution;
        uint256 executionCount;
        uint256 maxExecutions;
        bool active;
    }

    mapping(bytes32 => ScheduledSubscription) public scheduledSubscriptions;
    mapping(bytes32 => RecurringSchedule) public recurringSchedules;
    mapping(address => bytes32[]) public userSchedules;
    
    uint256 public scheduleCounter;

    event SubscriptionScheduled(bytes32 indexed scheduleId, address indexed subscriber, uint256 startDate);
    event ScheduledSubscriptionExecuted(bytes32 indexed scheduleId, address indexed subscriber);
    event ScheduledSubscriptionCancelled(bytes32 indexed scheduleId, address indexed subscriber);

    function scheduleSubscription(
        address creator,
        uint256 subscriptionId,
        uint256 startDate,
        uint256 endDate,
        string memory reason
    ) external payable returns (bytes32 scheduleId) {
        require(startDate > block.timestamp, "Start date must be in future");
        require(endDate > startDate, "End date must be after start date");
        require(msg.value > 0, "Payment required");

        scheduleId = keccak256(abi.encodePacked(
            msg.sender,
            creator,
            subscriptionId,
            startDate,
            scheduleCounter++
        ));

        scheduledSubscriptions[scheduleId] = ScheduledSubscription({
            subscriber: msg.sender,
            creator: creator,
            subscriptionId: subscriptionId,
            startDate: startDate,
            endDate: endDate,
            amount: msg.value,
            executed: false,
            cancelled: false,
            reason: reason
        });

        userSchedules[msg.sender].push(scheduleId);

        emit SubscriptionScheduled(scheduleId, msg.sender, startDate);
    }

    function scheduleRecurringSubscription(
        address creator,
        uint256 subscriptionId,
        uint256 startDate,
        uint256 interval,
        uint256 maxExecutions
    ) external payable returns (bytes32 scheduleId) {
        require(startDate > block.timestamp, "Start date must be in future");
        require(interval >= 1 days, "Interval too short");
        require(maxExecutions > 0, "Max executions must be positive");

        scheduleId = keccak256(abi.encodePacked(
            msg.sender,
            creator,
            subscriptionId,
            startDate,
            interval,
            scheduleCounter++
        ));

        scheduledSubscriptions[scheduleId] = ScheduledSubscription({
            subscriber: msg.sender,
            creator: creator,
            subscriptionId: subscriptionId,
            startDate: startDate,
            endDate: 0, // No end date for recurring
            amount: msg.value,
            executed: false,
            cancelled: false,
            reason: "Recurring subscription"
        });

        recurringSchedules[scheduleId] = RecurringSchedule({
            interval: interval,
            nextExecution: startDate,
            executionCount: 0,
            maxExecutions: maxExecutions,
            active: true
        });

        userSchedules[msg.sender].push(scheduleId);

        emit SubscriptionScheduled(scheduleId, msg.sender, startDate);
    }

    function executeScheduledSubscription(bytes32 scheduleId) external {
        ScheduledSubscription storage scheduled = scheduledSubscriptions[scheduleId];
        require(!scheduled.executed, "Already executed");
        require(!scheduled.cancelled, "Cancelled");
        require(block.timestamp >= scheduled.startDate, "Not yet time");

        RecurringSchedule storage recurring = recurringSchedules[scheduleId];
        
        if (recurring.active) {
            // Handle recurring subscription
            require(recurring.executionCount < recurring.maxExecutions, "Max executions reached");
            
            recurring.executionCount++;
            recurring.nextExecution = block.timestamp + recurring.interval;
            
            if (recurring.executionCount >= recurring.maxExecutions) {
                recurring.active = false;
                scheduled.executed = true;
            }
        } else {
            // Handle one-time scheduled subscription
            require(block.timestamp <= scheduled.endDate, "Execution window expired");
            scheduled.executed = true;
        }

        // Transfer payment to creator
        (bool success, ) = payable(scheduled.creator).call{value: scheduled.amount}("");
        require(success, "Payment failed");

        emit ScheduledSubscriptionExecuted(scheduleId, scheduled.subscriber);
    }

    function cancelScheduledSubscription(bytes32 scheduleId) external {
        ScheduledSubscription storage scheduled = scheduledSubscriptions[scheduleId];
        require(scheduled.subscriber == msg.sender, "Not your schedule");
        require(!scheduled.executed, "Already executed");
        require(!scheduled.cancelled, "Already cancelled");

        scheduled.cancelled = true;
        
        // Mark recurring schedule as inactive
        if (recurringSchedules[scheduleId].active) {
            recurringSchedules[scheduleId].active = false;
        }

        // Refund the payment
        (bool success, ) = payable(msg.sender).call{value: scheduled.amount}("");
        require(success, "Refund failed");

        emit ScheduledSubscriptionCancelled(scheduleId, msg.sender);
    }

    function isExecutionDue(bytes32 scheduleId) external view returns (bool) {
        ScheduledSubscription memory scheduled = scheduledSubscriptions[scheduleId];
        
        if (scheduled.executed || scheduled.cancelled) {
            return false;
        }

        RecurringSchedule memory recurring = recurringSchedules[scheduleId];
        
        if (recurring.active) {
            return block.timestamp >= recurring.nextExecution && 
                   recurring.executionCount < recurring.maxExecutions;
        } else {
            return block.timestamp >= scheduled.startDate && 
                   block.timestamp <= scheduled.endDate;
        }
    }

    function getScheduledSubscription(bytes32 scheduleId) external view returns (ScheduledSubscription memory) {
        return scheduledSubscriptions[scheduleId];
    }

    function getRecurringSchedule(bytes32 scheduleId) external view returns (RecurringSchedule memory) {
        return recurringSchedules[scheduleId];
    }

    function getUserSchedules(address user) external view returns (bytes32[] memory) {
        return userSchedules[user];
    }

    function getActiveSchedules(address user) external view returns (bytes32[] memory active) {
        bytes32[] memory allSchedules = userSchedules[user];
        uint256 activeCount = 0;

        // Count active schedules
        for (uint256 i = 0; i < allSchedules.length; i++) {
            ScheduledSubscription memory scheduled = scheduledSubscriptions[allSchedules[i]];
            if (!scheduled.executed && !scheduled.cancelled) {
                activeCount++;
            }
        }

        // Create array of active schedules
        active = new bytes32[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allSchedules.length; i++) {
            ScheduledSubscription memory scheduled = scheduledSubscriptions[allSchedules[i]];
            if (!scheduled.executed && !scheduled.cancelled) {
                active[index] = allSchedules[i];
                index++;
            }
        }
    }
}
