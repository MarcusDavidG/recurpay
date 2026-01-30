// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionBackup {
    struct BackupData {
        bytes32 dataHash;
        uint256 timestamp;
        string location;
        bool verified;
    }

    mapping(address => BackupData[]) public backups;
    mapping(bytes32 => bool) public restoredHashes;

    event BackupCreated(address indexed creator, bytes32 dataHash, string location);
    event BackupRestored(address indexed creator, bytes32 dataHash);

    function createBackup(bytes32 dataHash, string memory location) external {
        backups[msg.sender].push(BackupData({
            dataHash: dataHash,
            timestamp: block.timestamp,
            location: location,
            verified: false
        }));

        emit BackupCreated(msg.sender, dataHash, location);
    }

    function verifyBackup(uint256 backupIndex) external {
        require(backupIndex < backups[msg.sender].length, "Invalid backup index");
        backups[msg.sender][backupIndex].verified = true;
    }

    function restoreFromBackup(bytes32 dataHash) external {
        require(!restoredHashes[dataHash], "Already restored");
        restoredHashes[dataHash] = true;
        emit BackupRestored(msg.sender, dataHash);
    }
}
