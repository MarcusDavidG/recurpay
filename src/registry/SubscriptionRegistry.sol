// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionRegistry {
    struct RegistryEntry {
        address contractAddress;
        string version;
        bytes32 codeHash;
        uint256 registeredAt;
        bool active;
    }

    mapping(string => RegistryEntry) public registry;
    mapping(address => string[]) public contractNames;
    string[] public allContracts;

    event ContractRegistered(string indexed name, address contractAddress, string version);
    event ContractDeactivated(string indexed name);

    function registerContract(
        string memory name,
        address contractAddress,
        string memory version
    ) external {
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(contractAddress)
        }

        registry[name] = RegistryEntry({
            contractAddress: contractAddress,
            version: version,
            codeHash: codeHash,
            registeredAt: block.timestamp,
            active: true
        });

        contractNames[contractAddress].push(name);
        allContracts.push(name);

        emit ContractRegistered(name, contractAddress, version);
    }

    function deactivateContract(string memory name) external {
        registry[name].active = false;
        emit ContractDeactivated(name);
    }

    function getContract(string memory name) external view returns (address) {
        RegistryEntry memory entry = registry[name];
        return entry.active ? entry.contractAddress : address(0);
    }

    function isValidContract(string memory name, address contractAddress) external view returns (bool) {
        RegistryEntry memory entry = registry[name];
        return entry.active && entry.contractAddress == contractAddress;
    }
}
