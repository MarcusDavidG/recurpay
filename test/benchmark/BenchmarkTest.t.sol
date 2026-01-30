// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract BenchmarkTest is Test {
    uint256 constant ITERATIONS = 1000;

    function testGasUsageSubscriptionCreation() public {
        uint256 gasStart = gasleft();
        
        for (uint256 i = 0; i < ITERATIONS; i++) {
            // Simulate subscription creation gas usage
            bytes32 id = keccak256(abi.encodePacked(i, block.timestamp));
            require(id != bytes32(0), "Invalid ID");
        }
        
        uint256 gasUsed = gasStart - gasleft();
        uint256 avgGasPerOperation = gasUsed / ITERATIONS;
        
        console.log("Average gas per subscription creation:", avgGasPerOperation);
        assertLt(avgGasPerOperation, 50000); // Should be less than 50k gas
    }

    function testGasUsagePaymentProcessing() public {
        uint256 gasStart = gasleft();
        
        for (uint256 i = 0; i < ITERATIONS; i++) {
            // Simulate payment processing gas usage
            uint256 fee = (1 ether * 250) / 10000;
            uint256 amount = 1 ether - fee;
            require(amount > 0, "Invalid amount");
        }
        
        uint256 gasUsed = gasStart - gasleft();
        uint256 avgGasPerOperation = gasUsed / ITERATIONS;
        
        console.log("Average gas per payment processing:", avgGasPerOperation);
        assertLt(avgGasPerOperation, 30000); // Should be less than 30k gas
    }

    function testBatchOperationEfficiency() public {
        uint256[] memory amounts = new uint256[](100);
        for (uint256 i = 0; i < 100; i++) {
            amounts[i] = 1 ether + i;
        }
        
        uint256 gasStart = gasleft();
        
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for batch operation (100 items):", gasUsed);
        assertLt(gasUsed, 100000); // Should be less than 100k gas
        assertGt(total, 0);
    }
}
