// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract SetupTestEnvironment is Script {
    function run() external {
        console.log("Setting up test environment...");
        
        // Create test accounts
        address[] memory testAccounts = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            testAccounts[i] = vm.addr(i + 1);
            vm.deal(testAccounts[i], 100 ether);
            console.log("Test account", i, ":", testAccounts[i]);
        }
        
        // Set up test data
        console.log("Test environment ready!");
        console.log("- 10 test accounts created");
        console.log("- Each account funded with 100 ETH");
        console.log("- Ready for integration testing");
    }
}
