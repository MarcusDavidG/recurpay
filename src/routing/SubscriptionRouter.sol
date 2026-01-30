// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionRouter {
    mapping(string => address) public contracts;
    mapping(address => bool) public authorized;
    address public owner;

    event ContractUpdated(string name, address contractAddress);
    event RouteExecuted(string contractName, bytes4 selector, bool success);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorized[msg.sender] = true;
    }

    function setContract(string memory name, address contractAddress) external onlyOwner {
        contracts[name] = contractAddress;
        emit ContractUpdated(name, contractAddress);
    }

    function route(string memory contractName, bytes memory data) external onlyAuthorized returns (bytes memory) {
        address target = contracts[contractName];
        require(target != address(0), "Contract not found");

        (bool success, bytes memory result) = target.call(data);
        
        bytes4 selector;
        assembly {
            selector := mload(add(data, 0x20))
        }
        
        emit RouteExecuted(contractName, selector, success);
        
        if (!success) {
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        }
        
        return result;
    }

    function batchRoute(
        string[] memory contractNames,
        bytes[] memory data
    ) external onlyAuthorized returns (bytes[] memory results) {
        require(contractNames.length == data.length, "Array length mismatch");
        
        results = new bytes[](contractNames.length);
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            results[i] = this.route(contractNames[i], data[i]);
        }
    }

    function authorize(address user) external onlyOwner {
        authorized[user] = true;
    }

    function deauthorize(address user) external onlyOwner {
        authorized[user] = false;
    }
}
