// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ContentAccessControl {
    struct ContentItem {
        string contentId;
        address creator;
        uint256 requiredTier;
        bool isActive;
        uint256 createdAt;
        string contentType;
        bytes32 contentHash;
    }

    struct AccessPermission {
        bool hasAccess;
        uint256 grantedAt;
        uint256 expiresAt;
        uint256 accessCount;
        uint256 maxAccess;
    }

    mapping(bytes32 => ContentItem) public content;
    mapping(address => mapping(bytes32 => AccessPermission)) public userAccess;
    mapping(address => bytes32[]) public creatorContent;
    mapping(bytes32 => address[]) public contentSubscribers;
    
    uint256 public contentCounter;

    event ContentCreated(bytes32 indexed contentId, address indexed creator, uint256 requiredTier);
    event AccessGranted(bytes32 indexed contentId, address indexed user, uint256 expiresAt);
    event AccessRevoked(bytes32 indexed contentId, address indexed user);
    event ContentAccessed(bytes32 indexed contentId, address indexed user);

    function createContent(
        string memory contentId,
        uint256 requiredTier,
        string memory contentType,
        bytes32 contentHash
    ) external returns (bytes32 id) {
        id = keccak256(abi.encodePacked(
            msg.sender,
            contentId,
            block.timestamp,
            contentCounter++
        ));

        content[id] = ContentItem({
            contentId: contentId,
            creator: msg.sender,
            requiredTier: requiredTier,
            isActive: true,
            createdAt: block.timestamp,
            contentType: contentType,
            contentHash: contentHash
        });

        creatorContent[msg.sender].push(id);

        emit ContentCreated(id, msg.sender, requiredTier);
    }

    function grantAccess(
        bytes32 contentId,
        address user,
        uint256 duration,
        uint256 maxAccess
    ) external {
        ContentItem memory item = content[contentId];
        require(item.creator == msg.sender, "Not content creator");
        require(item.isActive, "Content not active");

        userAccess[user][contentId] = AccessPermission({
            hasAccess: true,
            grantedAt: block.timestamp,
            expiresAt: block.timestamp + duration,
            accessCount: 0,
            maxAccess: maxAccess
        });

        contentSubscribers[contentId].push(user);

        emit AccessGranted(contentId, user, block.timestamp + duration);
    }

    function revokeAccess(bytes32 contentId, address user) external {
        ContentItem memory item = content[contentId];
        require(item.creator == msg.sender, "Not content creator");

        userAccess[user][contentId].hasAccess = false;

        emit AccessRevoked(contentId, user);
    }

    function accessContent(bytes32 contentId) external returns (bool success) {
        AccessPermission storage permission = userAccess[msg.sender][contentId];
        ContentItem memory item = content[contentId];

        require(item.isActive, "Content not active");
        require(permission.hasAccess, "No access permission");
        require(block.timestamp <= permission.expiresAt, "Access expired");
        require(permission.accessCount < permission.maxAccess, "Access limit reached");

        permission.accessCount++;

        emit ContentAccessed(contentId, msg.sender);
        return true;
    }

    function checkAccess(address user, bytes32 contentId) external view returns (bool hasAccess) {
        AccessPermission memory permission = userAccess[user][contentId];
        ContentItem memory item = content[contentId];

        return item.isActive &&
               permission.hasAccess &&
               block.timestamp <= permission.expiresAt &&
               permission.accessCount < permission.maxAccess;
    }

    function batchGrantAccess(
        bytes32 contentId,
        address[] memory users,
        uint256 duration,
        uint256 maxAccess
    ) external {
        ContentItem memory item = content[contentId];
        require(item.creator == msg.sender, "Not content creator");
        require(item.isActive, "Content not active");

        for (uint256 i = 0; i < users.length; i++) {
            userAccess[users[i]][contentId] = AccessPermission({
                hasAccess: true,
                grantedAt: block.timestamp,
                expiresAt: block.timestamp + duration,
                accessCount: 0,
                maxAccess: maxAccess
            });

            contentSubscribers[contentId].push(users[i]);
            emit AccessGranted(contentId, users[i], block.timestamp + duration);
        }
    }

    function updateContentTier(bytes32 contentId, uint256 newRequiredTier) external {
        ContentItem storage item = content[contentId];
        require(item.creator == msg.sender, "Not content creator");

        item.requiredTier = newRequiredTier;
    }

    function deactivateContent(bytes32 contentId) external {
        ContentItem storage item = content[contentId];
        require(item.creator == msg.sender, "Not content creator");

        item.isActive = false;
    }

    function getContentItem(bytes32 contentId) external view returns (ContentItem memory) {
        return content[contentId];
    }

    function getUserAccess(address user, bytes32 contentId) external view returns (AccessPermission memory) {
        return userAccess[user][contentId];
    }

    function getCreatorContent(address creator) external view returns (bytes32[] memory) {
        return creatorContent[creator];
    }

    function getContentSubscribers(bytes32 contentId) external view returns (address[] memory) {
        return contentSubscribers[contentId];
    }

    function getUserAccessibleContent(address user) external view returns (bytes32[] memory accessible) {
        // This would return all content the user has access to
        // Simplified implementation - would need to iterate through all content
        bytes32[] memory userContent = new bytes32[](0);
        return userContent;
    }

    function getRemainingAccess(address user, bytes32 contentId) external view returns (uint256) {
        AccessPermission memory permission = userAccess[user][contentId];
        
        if (!permission.hasAccess || block.timestamp > permission.expiresAt) {
            return 0;
        }
        
        return permission.maxAccess - permission.accessCount;
    }

    function getAccessTimeRemaining(address user, bytes32 contentId) external view returns (uint256) {
        AccessPermission memory permission = userAccess[user][contentId];
        
        if (!permission.hasAccess || block.timestamp >= permission.expiresAt) {
            return 0;
        }
        
        return permission.expiresAt - block.timestamp;
    }
}
