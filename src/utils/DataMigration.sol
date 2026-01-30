// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DataMigration {
    struct MigrationJob {
        bytes32 jobId;
        address initiator;
        string sourceContract;
        string targetContract;
        uint256 totalRecords;
        uint256 migratedRecords;
        bool completed;
        uint256 startTime;
        uint256 endTime;
        string status;
    }

    mapping(bytes32 => MigrationJob) public migrationJobs;
    mapping(address => bytes32[]) public userMigrations;
    
    uint256 public jobCounter;

    event MigrationStarted(bytes32 indexed jobId, address indexed initiator);
    event MigrationCompleted(bytes32 indexed jobId, uint256 recordsMigrated);
    event MigrationFailed(bytes32 indexed jobId, string reason);

    function startMigration(
        string memory sourceContract,
        string memory targetContract,
        uint256 totalRecords
    ) external returns (bytes32 jobId) {
        jobId = keccak256(abi.encodePacked(msg.sender, sourceContract, targetContract, jobCounter++));
        
        migrationJobs[jobId] = MigrationJob({
            jobId: jobId,
            initiator: msg.sender,
            sourceContract: sourceContract,
            targetContract: targetContract,
            totalRecords: totalRecords,
            migratedRecords: 0,
            completed: false,
            startTime: block.timestamp,
            endTime: 0,
            status: "IN_PROGRESS"
        });

        userMigrations[msg.sender].push(jobId);
        emit MigrationStarted(jobId, msg.sender);
    }

    function updateMigrationProgress(bytes32 jobId, uint256 recordsMigrated) external {
        MigrationJob storage job = migrationJobs[jobId];
        require(job.initiator == msg.sender, "Not job initiator");
        require(!job.completed, "Migration already completed");
        
        job.migratedRecords = recordsMigrated;
        
        if (recordsMigrated >= job.totalRecords) {
            job.completed = true;
            job.endTime = block.timestamp;
            job.status = "COMPLETED";
            emit MigrationCompleted(jobId, recordsMigrated);
        }
    }

    function failMigration(bytes32 jobId, string memory reason) external {
        MigrationJob storage job = migrationJobs[jobId];
        require(job.initiator == msg.sender, "Not job initiator");
        
        job.completed = true;
        job.endTime = block.timestamp;
        job.status = "FAILED";
        
        emit MigrationFailed(jobId, reason);
    }

    function getMigrationJob(bytes32 jobId) external view returns (MigrationJob memory) {
        return migrationJobs[jobId];
    }

    function getUserMigrations(address user) external view returns (bytes32[] memory) {
        return userMigrations[user];
    }

    function getMigrationProgress(bytes32 jobId) external view returns (uint256 percentage) {
        MigrationJob memory job = migrationJobs[jobId];
        if (job.totalRecords == 0) return 0;
        return (job.migratedRecords * 100) / job.totalRecords;
    }
}
