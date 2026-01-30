// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DistributedLock {
    struct Lock {
        address holder;
        uint256 acquiredAt;
        uint256 expiresAt;
        bool active;
        string resource;
    }

    mapping(bytes32 => Lock) public locks;
    mapping(address => bytes32[]) public holderLocks;
    mapping(string => bytes32) public resourceLocks;

    event LockAcquired(bytes32 indexed lockId, address holder, string resource);
    event LockReleased(bytes32 indexed lockId, address holder);
    event LockExpired(bytes32 indexed lockId);

    function acquireLock(string memory resource, uint256 duration) external returns (bytes32 lockId) {
        bytes32 existingLockId = resourceLocks[resource];
        
        // Check if resource is already locked
        if (existingLockId != bytes32(0)) {
            Lock storage existingLock = locks[existingLockId];
            require(
                !existingLock.active || block.timestamp >= existingLock.expiresAt,
                "Resource already locked"
            );
            
            if (block.timestamp >= existingLock.expiresAt) {
                existingLock.active = false;
                emit LockExpired(existingLockId);
            }
        }

        lockId = keccak256(abi.encodePacked(msg.sender, resource, block.timestamp));
        
        locks[lockId] = Lock({
            holder: msg.sender,
            acquiredAt: block.timestamp,
            expiresAt: block.timestamp + duration,
            active: true,
            resource: resource
        });

        holderLocks[msg.sender].push(lockId);
        resourceLocks[resource] = lockId;

        emit LockAcquired(lockId, msg.sender, resource);
    }

    function releaseLock(bytes32 lockId) external {
        Lock storage lock = locks[lockId];
        require(lock.holder == msg.sender, "Not lock holder");
        require(lock.active, "Lock not active");

        lock.active = false;
        delete resourceLocks[lock.resource];

        emit LockReleased(lockId, msg.sender);
    }

    function renewLock(bytes32 lockId, uint256 additionalDuration) external {
        Lock storage lock = locks[lockId];
        require(lock.holder == msg.sender, "Not lock holder");
        require(lock.active, "Lock not active");
        require(block.timestamp < lock.expiresAt, "Lock expired");

        lock.expiresAt += additionalDuration;
    }

    function isLocked(string memory resource) external view returns (bool) {
        bytes32 lockId = resourceLocks[resource];
        if (lockId == bytes32(0)) return false;

        Lock memory lock = locks[lockId];
        return lock.active && block.timestamp < lock.expiresAt;
    }

    function getLockHolder(string memory resource) external view returns (address) {
        bytes32 lockId = resourceLocks[resource];
        if (lockId == bytes32(0)) return address(0);

        Lock memory lock = locks[lockId];
        if (!lock.active || block.timestamp >= lock.expiresAt) {
            return address(0);
        }

        return lock.holder;
    }

    function cleanupExpiredLocks(bytes32[] memory lockIds) external {
        for (uint256 i = 0; i < lockIds.length; i++) {
            Lock storage lock = locks[lockIds[i]];
            if (lock.active && block.timestamp >= lock.expiresAt) {
                lock.active = false;
                delete resourceLocks[lock.resource];
                emit LockExpired(lockIds[i]);
            }
        }
    }
}
