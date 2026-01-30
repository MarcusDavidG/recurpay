// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionIndexer {
    struct IndexEntry {
        bytes32 key;
        bytes32 value;
        uint256 timestamp;
        bool active;
    }

    mapping(bytes32 => IndexEntry) public entries;
    mapping(string => bytes32[]) public indexes;
    mapping(bytes32 => string[]) public entryIndexes;

    event EntryIndexed(bytes32 indexed key, bytes32 value, string[] indexes);
    event EntryRemoved(bytes32 indexed key);

    function indexEntry(
        bytes32 key,
        bytes32 value,
        string[] memory indexNames
    ) external {
        entries[key] = IndexEntry({
            key: key,
            value: value,
            timestamp: block.timestamp,
            active: true
        });

        for (uint256 i = 0; i < indexNames.length; i++) {
            indexes[indexNames[i]].push(key);
            entryIndexes[key].push(indexNames[i]);
        }

        emit EntryIndexed(key, value, indexNames);
    }

    function removeEntry(bytes32 key) external {
        require(entries[key].active, "Entry not active");
        
        entries[key].active = false;
        
        string[] memory entryIndexNames = entryIndexes[key];
        for (uint256 i = 0; i < entryIndexNames.length; i++) {
            removeFromIndex(entryIndexNames[i], key);
        }

        emit EntryRemoved(key);
    }

    function removeFromIndex(string memory indexName, bytes32 key) internal {
        bytes32[] storage indexEntries = indexes[indexName];
        for (uint256 i = 0; i < indexEntries.length; i++) {
            if (indexEntries[i] == key) {
                indexEntries[i] = indexEntries[indexEntries.length - 1];
                indexEntries.pop();
                break;
            }
        }
    }

    function getIndexEntries(string memory indexName) external view returns (bytes32[] memory) {
        return indexes[indexName];
    }

    function getEntry(bytes32 key) external view returns (IndexEntry memory) {
        return entries[key];
    }

    function searchIndex(string memory indexName, uint256 limit) external view returns (bytes32[] memory results) {
        bytes32[] memory allEntries = indexes[indexName];
        uint256 resultCount = allEntries.length > limit ? limit : allEntries.length;
        
        results = new bytes32[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            results[i] = allEntries[i];
        }
    }
}
