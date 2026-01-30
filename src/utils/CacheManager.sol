// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CacheManager {
    struct CacheEntry {
        bytes data;
        uint256 timestamp;
        uint256 ttl;
        bool valid;
    }

    mapping(bytes32 => CacheEntry) public cache;
    mapping(address => bytes32[]) public userCacheKeys;

    function setCache(bytes32 key, bytes memory data, uint256 ttl) external {
        cache[key] = CacheEntry({
            data: data,
            timestamp: block.timestamp,
            ttl: ttl,
            valid: true
        });

        userCacheKeys[msg.sender].push(key);
    }

    function getCache(bytes32 key) external view returns (bytes memory data, bool valid) {
        CacheEntry memory entry = cache[key];
        
        if (!entry.valid || block.timestamp > entry.timestamp + entry.ttl) {
            return ("", false);
        }
        
        return (entry.data, true);
    }

    function invalidateCache(bytes32 key) external {
        cache[key].valid = false;
    }

    function isCacheValid(bytes32 key) external view returns (bool) {
        CacheEntry memory entry = cache[key];
        return entry.valid && block.timestamp <= entry.timestamp + entry.ttl;
    }
}
