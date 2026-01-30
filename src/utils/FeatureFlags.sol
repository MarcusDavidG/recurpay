// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FeatureFlags {
    struct Flag {
        bool enabled;
        uint256 rolloutPercentage;
        uint256 createdAt;
        uint256 updatedAt;
        address creator;
        string description;
    }

    mapping(string => Flag) public flags;
    mapping(string => mapping(address => bool)) public userOverrides;
    mapping(address => string[]) public userFlags;

    event FlagCreated(string indexed flagName, address indexed creator);
    event FlagUpdated(string indexed flagName, bool enabled, uint256 rolloutPercentage);
    event UserOverrideSet(string indexed flagName, address indexed user, bool enabled);

    function createFlag(
        string memory flagName,
        bool enabled,
        uint256 rolloutPercentage,
        string memory description
    ) external {
        require(flags[flagName].creator == address(0), "Flag already exists");
        
        flags[flagName] = Flag({
            enabled: enabled,
            rolloutPercentage: rolloutPercentage,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            creator: msg.sender,
            description: description
        });

        emit FlagCreated(flagName, msg.sender);
    }

    function updateFlag(
        string memory flagName,
        bool enabled,
        uint256 rolloutPercentage
    ) external {
        Flag storage flag = flags[flagName];
        require(flag.creator == msg.sender, "Not flag creator");
        
        flag.enabled = enabled;
        flag.rolloutPercentage = rolloutPercentage;
        flag.updatedAt = block.timestamp;

        emit FlagUpdated(flagName, enabled, rolloutPercentage);
    }

    function setUserOverride(
        string memory flagName,
        address user,
        bool enabled
    ) external {
        Flag memory flag = flags[flagName];
        require(flag.creator == msg.sender, "Not flag creator");
        
        userOverrides[flagName][user] = enabled;
        userFlags[user].push(flagName);

        emit UserOverrideSet(flagName, user, enabled);
    }

    function isEnabled(string memory flagName, address user) external view returns (bool) {
        Flag memory flag = flags[flagName];
        
        // Check user override first
        if (userOverrides[flagName][user]) {
            return true;
        }
        
        // Check if flag is globally enabled
        if (!flag.enabled) {
            return false;
        }
        
        // Check rollout percentage
        if (flag.rolloutPercentage >= 100) {
            return true;
        }
        
        // Use user address for deterministic rollout
        uint256 userHash = uint256(keccak256(abi.encodePacked(user, flagName))) % 100;
        return userHash < flag.rolloutPercentage;
    }

    function getFlag(string memory flagName) external view returns (Flag memory) {
        return flags[flagName];
    }

    function getUserFlags(address user) external view returns (string[] memory) {
        return userFlags[user];
    }
}
