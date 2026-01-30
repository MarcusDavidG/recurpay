// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract GenerateTestData is Script {
    function run() external {
        console.log("Generating test data...");
        
        // Generate subscription IDs
        bytes32[] memory subscriptionIds = new bytes32[](100);
        for (uint256 i = 0; i < 100; i++) {
            subscriptionIds[i] = keccak256(abi.encodePacked("subscription", i, block.timestamp));
        }
        
        // Generate plan IDs
        uint256[] memory planIds = new uint256[](50);
        for (uint256 i = 0; i < 50; i++) {
            planIds[i] = i + 1;
        }
        
        // Generate test prices
        uint256[] memory prices = new uint256[](20);
        prices[0] = 0.01 ether;
        prices[1] = 0.05 ether;
        prices[2] = 0.1 ether;
        prices[3] = 0.5 ether;
        prices[4] = 1 ether;
        prices[5] = 5 ether;
        prices[6] = 10 ether;
        prices[7] = 50 ether;
        prices[8] = 100 ether;
        prices[9] = 0.001 ether;
        
        for (uint256 i = 10; i < 20; i++) {
            prices[i] = (i - 9) * 0.1 ether;
        }
        
        console.log("Generated test data:");
        console.log("- 100 subscription IDs");
        console.log("- 50 plan IDs");
        console.log("- 20 test price points");
        console.log("Test data generation complete!");
    }
}
