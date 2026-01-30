// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionMigrator {
    struct MigrationPlan {
        address sourceContract;
        address targetContract;
        bytes32[] subscriptionIds;
        uint256 startTime;
        uint256 batchSize;
        uint256 currentBatch;
        bool completed;
    }

    mapping(bytes32 => MigrationPlan) public migrationPlans;
    mapping(address => bytes32[]) public contractMigrations;

    event MigrationPlanCreated(bytes32 indexed planId, address source, address target);
    event BatchMigrated(bytes32 indexed planId, uint256 batchNumber, uint256 count);

    function createMigrationPlan(
        address sourceContract,
        address targetContract,
        bytes32[] memory subscriptionIds,
        uint256 batchSize
    ) external returns (bytes32 planId) {
        planId = keccak256(abi.encodePacked(sourceContract, targetContract, block.timestamp));
        
        migrationPlans[planId] = MigrationPlan({
            sourceContract: sourceContract,
            targetContract: targetContract,
            subscriptionIds: subscriptionIds,
            startTime: block.timestamp,
            batchSize: batchSize,
            currentBatch: 0,
            completed: false
        });

        contractMigrations[sourceContract].push(planId);
        emit MigrationPlanCreated(planId, sourceContract, targetContract);
    }

    function executeBatch(bytes32 planId) external {
        MigrationPlan storage plan = migrationPlans[planId];
        require(!plan.completed, "Migration completed");

        uint256 startIndex = plan.currentBatch * plan.batchSize;
        uint256 endIndex = startIndex + plan.batchSize;
        if (endIndex > plan.subscriptionIds.length) {
            endIndex = plan.subscriptionIds.length;
        }

        uint256 migratedCount = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            // Simulate migration logic
            migratedCount++;
        }

        plan.currentBatch++;
        
        if (endIndex >= plan.subscriptionIds.length) {
            plan.completed = true;
        }

        emit BatchMigrated(planId, plan.currentBatch, migratedCount);
    }

    function getMigrationProgress(bytes32 planId) external view returns (uint256 percentage) {
        MigrationPlan memory plan = migrationPlans[planId];
        if (plan.subscriptionIds.length == 0) return 0;
        
        uint256 processed = plan.currentBatch * plan.batchSize;
        if (processed > plan.subscriptionIds.length) {
            processed = plan.subscriptionIds.length;
        }
        
        return (processed * 100) / plan.subscriptionIds.length;
    }
}
