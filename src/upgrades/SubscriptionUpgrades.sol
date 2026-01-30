// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionUpgrades {
    mapping(address => uint256) public contractVersions;
    mapping(uint256 => address) public versionImplementations;
    
    uint256 public currentVersion = 1;
    address public upgradeAuthority;

    event ContractUpgraded(address indexed contract_, uint256 newVersion);

    modifier onlyUpgradeAuthority() {
        require(msg.sender == upgradeAuthority, "Not authorized");
        _;
    }

    constructor() {
        upgradeAuthority = msg.sender;
    }

    function registerImplementation(uint256 version, address implementation) external onlyUpgradeAuthority {
        versionImplementations[version] = implementation;
    }

    function upgradeContract(address contract_, uint256 newVersion) external onlyUpgradeAuthority {
        require(versionImplementations[newVersion] != address(0), "Version not registered");
        contractVersions[contract_] = newVersion;
        emit ContractUpgraded(contract_, newVersion);
    }

    function getImplementation(uint256 version) external view returns (address) {
        return versionImplementations[version];
    }

    function getCurrentImplementation() external view returns (address) {
        return versionImplementations[currentVersion];
    }
}
