// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionConfig {
    struct Config {
        string key;
        bytes value;
        uint256 updatedAt;
        bool active;
    }

    mapping(string => Config) public configs;
    mapping(address => bool) public authorized;
    string[] public configKeys;

    event ConfigUpdated(string key, bytes value);
    event ConfigRemoved(string key);

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    constructor() {
        authorized[msg.sender] = true;
    }

    function setConfig(string memory key, bytes memory value) external onlyAuthorized {
        if (!configs[key].active) {
            configKeys.push(key);
        }
        
        configs[key] = Config({
            key: key,
            value: value,
            updatedAt: block.timestamp,
            active: true
        });

        emit ConfigUpdated(key, value);
    }

    function removeConfig(string memory key) external onlyAuthorized {
        require(configs[key].active, "Config not found");
        configs[key].active = false;
        emit ConfigRemoved(key);
    }

    function getConfig(string memory key) external view returns (bytes memory) {
        require(configs[key].active, "Config not found");
        return configs[key].value;
    }

    function getConfigAsUint(string memory key) external view returns (uint256) {
        bytes memory value = this.getConfig(key);
        return abi.decode(value, (uint256));
    }

    function getConfigAsString(string memory key) external view returns (string memory) {
        bytes memory value = this.getConfig(key);
        return abi.decode(value, (string));
    }

    function getAllConfigKeys() external view returns (string[] memory) {
        return configKeys;
    }

    function authorize(address user) external onlyAuthorized {
        authorized[user] = true;
    }
}
