// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/bridge/SubscriptionBridge.sol";

contract SubscriptionBridgeTest is Test {
    SubscriptionBridge bridge;
    address user = address(0x1);
    address validator = address(0x2);

    function setUp() public {
        bridge = new SubscriptionBridge();
        bridge.addSupportedChain(1); // Ethereum
        bridge.addSupportedChain(137); // Polygon
        bridge.addValidator(validator);
    }

    function testInitiateBridge() public {
        vm.prank(user);
        bytes32 requestId = bridge.initiateBridge(1, 137);

        (address requestUser, uint256 subscriptionId, uint256 sourceChain, uint256 targetChain, bytes32 requestHash, bool processed) = 
            bridge.bridgeRequests(requestId);

        assertEq(requestUser, user);
        assertEq(subscriptionId, 1);
        assertEq(targetChain, 137);
        assertFalse(processed);
    }

    function testCompleteBridge() public {
        vm.prank(user);
        bytes32 requestId = bridge.initiateBridge(1, 137);

        bytes memory proof = "valid_proof";
        vm.prank(validator);
        bridge.completeBridge(requestId, proof);

        (, , , , , bool processed) = bridge.bridgeRequests(requestId);
        assertTrue(processed);
    }

    function testFailUnsupportedChain() public {
        vm.prank(user);
        vm.expectRevert("Chain not supported");
        bridge.initiateBridge(1, 999); // Unsupported chain
    }

    function testFailUnauthorizedValidator() public {
        vm.prank(user);
        bytes32 requestId = bridge.initiateBridge(1, 137);

        bytes memory proof = "valid_proof";
        vm.expectRevert("Not validator");
        bridge.completeBridge(requestId, proof);
    }
}
