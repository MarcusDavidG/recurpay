// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/staking/SubscriptionStaking.sol";

contract SubscriptionStakingTest is Test {
    SubscriptionStaking staking;
    address user = address(0x1);

    function setUp() public {
        staking = new SubscriptionStaking();
        vm.deal(user, 10 ether);
    }

    function testStaking() public {
        vm.prank(user);
        staking.stake{value: 1 ether}(30 days);

        (uint256 amount, uint256 stakedAt, uint256 lockPeriod, uint256 rewardRate, bool active) = staking.stakes(user);
        assertEq(amount, 1 ether);
        assertEq(lockPeriod, 30 days);
        assertEq(rewardRate, 700); // Base + lock bonus
        assertTrue(active);
    }

    function testRewardCalculation() public {
        vm.prank(user);
        staking.stake{value: 1 ether}(30 days);

        vm.warp(block.timestamp + 365 days);
        
        uint256 pendingRewards = staking.calculatePendingRewards(user);
        assertGt(pendingRewards, 0);
    }

    function testUnstaking() public {
        vm.prank(user);
        staking.stake{value: 1 ether}(30 days);

        vm.warp(block.timestamp + 30 days + 1);
        
        uint256 balanceBefore = user.balance;
        vm.prank(user);
        staking.unstake();
        
        assertEq(user.balance, balanceBefore + 1 ether);
    }

    function testFailEarlyUnstake() public {
        vm.prank(user);
        staking.stake{value: 1 ether}(30 days);

        vm.expectRevert("Still locked");
        vm.prank(user);
        staking.unstake();
    }
}
