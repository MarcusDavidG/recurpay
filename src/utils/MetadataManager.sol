// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MetadataManager {
    struct Metadata {
        string name;
        string description;
        string imageUrl;
        string[] tags;
        mapping(string => string) customFields;
        uint256 lastUpdated;
    }

    mapping(bytes32 => Metadata) public metadata;
    mapping(bytes32 => string[]) public metadataKeys;

    event MetadataUpdated(bytes32 indexed entityId, string field, string value);

    function setMetadata(
        bytes32 entityId,
        string memory name,
        string memory description,
        string memory imageUrl,
        string[] memory tags
    ) external {
        Metadata storage meta = metadata[entityId];
        meta.name = name;
        meta.description = description;
        meta.imageUrl = imageUrl;
        meta.tags = tags;
        meta.lastUpdated = block.timestamp;

        emit MetadataUpdated(entityId, "name", name);
    }

    function setCustomField(
        bytes32 entityId,
        string memory key,
        string memory value
    ) external {
        metadata[entityId].customFields[key] = value;
        metadata[entityId].lastUpdated = block.timestamp;
        
        // Track keys for enumeration
        metadataKeys[entityId].push(key);

        emit MetadataUpdated(entityId, key, value);
    }

    function getCustomField(bytes32 entityId, string memory key) external view returns (string memory) {
        return metadata[entityId].customFields[key];
    }

    function getMetadataKeys(bytes32 entityId) external view returns (string[] memory) {
        return metadataKeys[entityId];
    }
}
