// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/insurance/SubscriptionInsurancePool.sol";

contract SubscriptionInsurancePoolTest is Test {
    SubscriptionInsurancePool insurance;
    bytes32 poolId = keccak256("test-pool");
    address user = address(0x1);

    function setUp() public {
        insurance = new SubscriptionInsurancePool();
        vm.deal(user, 10 ether);
    }

    function testCreateInsurancePool() public {
        insurance.createInsurancePool{value: 5 ether}(poolId, 1000); // 10% premium rate

        (uint256 totalFunds, uint256 totalCoverage, uint256 premiumRate, uint256 claimsPaid, bool active) = insurance.pools(poolId);
        assertEq(totalFunds, 5 ether);
        assertEq(totalCoverage, 0);
        assertEq(premiumRate, 1000);
        assertEq(claimsPaid, 0);
        assertTrue(active);
    }

    function testPurchasePolicy() public {
        insurance.createInsurancePool{value: 5 ether}(poolId, 1000);

        vm.prank(user);
        bytes32 policyId = insurance.purchasePolicy{value: 0.1 ether}(poolId, 1 ether, 365 days);

        (address holder, uint256 coverage, uint256 premium, uint256 startTime, uint256 duration, bool active, uint256 claimCount) = insurance.policies(policyId);
        assertEq(holder, user);
        assertEq(coverage, 1 ether);
        assertTrue(active);
        assertEq(claimCount, 0);
    }

    function testFileClaim() public {
        insurance.createInsurancePool{value: 5 ether}(poolId, 1000);

        vm.prank(user);
        bytes32 policyId = insurance.purchasePolicy{value: 0.1 ether}(poolId, 1 ether, 365 days);

        uint256 balanceBefore = user.balance;
        vm.prank(user);
        insurance.fileClaim(policyId, 0.5 ether, "Test claim");

        assertEq(user.balance, balanceBefore + 0.5 ether);
    }

    function testAddFundsToPool() public {
        insurance.createInsurancePool{value: 5 ether}(poolId, 1000);

        insurance.addFundsToPool{value: 2 ether}(poolId);

        (uint256 totalFunds, , , ,) = insurance.pools(poolId);
        assertEq(totalFunds, 7 ether);
    }
}
