// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SubscriptionFactory.sol";
import "../src/PaymentProcessor.sol";

contract CoreContractsTest is Test {
    SubscriptionFactory factory;
    PaymentProcessor processor;
    
    address creator = address(0x1);
    address subscriber = address(0x2);
    
    function setUp() public {
        factory = new SubscriptionFactory();
        processor = new PaymentProcessor();
        
        vm.deal(subscriber, 10 ether);
    }
    
    function testCreateSubscription() public {
        vm.prank(creator);
        bytes32 subscriptionId = factory.createSubscription(
            1 ether,
            30 days,
            "Test Subscription"
        );
        
        assertNotEq(subscriptionId, bytes32(0));
    }
    
    function testSubscribeToService() public {
        vm.prank(creator);
        bytes32 subscriptionId = factory.createSubscription(
            1 ether,
            30 days,
            "Test Subscription"
        );
        
        vm.prank(subscriber);
        vm.deal(subscriber, 2 ether);
        factory.subscribe{value: 1 ether}(subscriptionId);
        
        assertTrue(factory.isActiveSubscriber(subscriptionId, subscriber));
    }
    
    function testPaymentProcessing() public {
        vm.prank(creator);
        bytes32 subscriptionId = factory.createSubscription(
            1 ether,
            30 days,
            "Test Subscription"
        );
        
        vm.prank(subscriber);
        factory.subscribe{value: 1 ether}(subscriptionId);
        
        // Fast forward time
        vm.warp(block.timestamp + 31 days);
        
        vm.prank(address(processor));
        bool success = processor.processPayment(subscriptionId, subscriber);
        assertTrue(success);
    }
    
    function testFailInsufficientPayment() public {
        vm.prank(creator);
        bytes32 subscriptionId = factory.createSubscription(
            1 ether,
            30 days,
            "Test Subscription"
        );
        
        vm.prank(subscriber);
        vm.expectRevert("Insufficient payment");
        factory.subscribe{value: 0.5 ether}(subscriptionId);
    }
}
