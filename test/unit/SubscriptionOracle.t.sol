// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/oracles/SubscriptionOracle.sol";

contract SubscriptionOracleTest is Test {
    SubscriptionOracle oracle;
    address updater = address(0x1);

    function setUp() public {
        oracle = new SubscriptionOracle();
        oracle.authorizeUpdater(updater);
    }

    function testUpdatePrice() public {
        vm.prank(updater);
        oracle.updatePrice("ETH", 2000e18);

        (uint256 price, bool valid) = oracle.getPrice("ETH");
        assertEq(price, 2000e18);
        assertTrue(valid);
    }

    function testPriceDeviation() public {
        vm.prank(updater);
        oracle.updatePrice("ETH", 2000e18);

        oracle.setDeviationThreshold("ETH", 1000); // 10%

        vm.prank(updater);
        vm.expectRevert("Price deviation too high");
        oracle.updatePrice("ETH", 3000e18); // 50% increase
    }

    function testStalePrice() public {
        vm.prank(updater);
        oracle.updatePrice("ETH", 2000e18);

        vm.warp(block.timestamp + 2 hours);

        (uint256 price, bool valid) = oracle.getPrice("ETH");
        assertEq(price, 2000e18);
        assertFalse(valid); // Should be stale
    }

    function testFailUnauthorizedUpdate() public {
        vm.expectRevert("Not authorized");
        oracle.updatePrice("ETH", 2000e18);
    }
}
