// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/tokenomics/SubscriptionTokenomics.sol";

contract SubscriptionTokenomicsTest is Test {
    SubscriptionTokenomics tokenomics;
    address user = address(0x1);

    function setUp() public {
        tokenomics = new SubscriptionTokenomics();
        // Give user some tokens
        vm.store(address(tokenomics), keccak256(abi.encode(user, 5)), bytes32(uint256(1000 * 10**18)));
    }

    function testStaking() public {
        vm.prank(user);
        tokenomics.stake(500 * 10**18);
        
        assertEq(tokenomics.stakingBalances(user), 500 * 10**18);
        assertEq(tokenomics.balances(user), 500 * 10**18);
    }

    function testUnstaking() public {
        vm.prank(user);
        tokenomics.stake(500 * 10**18);
        
        vm.prank(user);
        tokenomics.unstake(200 * 10**18);
        
        assertEq(tokenomics.stakingBalances(user), 300 * 10**18);
        assertEq(tokenomics.balances(user), 700 * 10**18);
    }

    function testRewardsCalculation() public {
        vm.prank(user);
        tokenomics.stake(1000 * 10**18);
        
        uint256 rewards = tokenomics.calculateRewards(user);
        assertEq(rewards, 50 * 10**18); // 5% of 1000
    }
}
