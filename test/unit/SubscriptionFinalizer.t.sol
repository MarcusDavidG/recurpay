// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/finalization/SubscriptionFinalizer.sol";

contract SubscriptionFinalizerTest is Test {
    SubscriptionFinalizer finalizer;

    function setUp() public {
        finalizer = new SubscriptionFinalizer();
    }

    function testFinalization() public {
        assertFalse(finalizer.isFinalized());
        
        finalizer.finalizeProtocol();
        
        assertTrue(finalizer.isFinalized());
        assertEq(finalizer.finalizedAt(), block.timestamp);
    }

    function testFailDoubleFinalization() public {
        finalizer.finalizeProtocol();
        
        vm.expectRevert("Already finalized");
        finalizer.finalizeProtocol();
    }

    function testFailUnauthorizedFinalization() public {
        vm.prank(address(0x999));
        vm.expectRevert("Not finalizer");
        finalizer.finalizeProtocol();
    }
}
