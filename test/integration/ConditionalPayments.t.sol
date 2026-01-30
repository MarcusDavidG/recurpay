// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/payments/ConditionalPayments.sol";

contract ConditionalPaymentsIntegrationTest is Test {
    ConditionalPayments conditionalPayments;
    address payer = address(0x1);
    address payee = address(0x2);

    function setUp() public {
        conditionalPayments = new ConditionalPayments();
        vm.deal(payer, 10 ether);
    }

    function testTimeBasedConditionalPayment() public {
        ConditionalPayments.ConditionType[] memory conditionTypes = new ConditionalPayments.ConditionType[](1);
        conditionTypes[0] = ConditionalPayments.ConditionType.TIME_BASED;

        bytes[] memory conditionData = new bytes[](1);
        conditionData[0] = abi.encode(block.timestamp + 1 days);

        vm.prank(payer);
        bytes32 paymentId = conditionalPayments.createConditionalPayment{value: 1 ether}(
            payee,
            conditionTypes,
            conditionData
        );

        // Try to fulfill before time
        vm.expectRevert("Time condition not met");
        conditionalPayments.fulfillCondition(paymentId, 0, "");

        // Fast forward time
        vm.warp(block.timestamp + 1 days + 1);

        uint256 balanceBefore = payee.balance;
        conditionalPayments.fulfillCondition(paymentId, 0, "");

        assertEq(payee.balance, balanceBefore + 1 ether);
    }

    function testMultipleConditions() public {
        ConditionalPayments.ConditionType[] memory conditionTypes = new ConditionalPayments.ConditionType[](2);
        conditionTypes[0] = ConditionalPayments.ConditionType.TIME_BASED;
        conditionTypes[1] = ConditionalPayments.ConditionType.ORACLE_BASED;

        bytes[] memory conditionData = new bytes[](2);
        conditionData[0] = abi.encode(block.timestamp + 1 days);
        conditionData[1] = abi.encode("oracle_data");

        vm.prank(payer);
        bytes32 paymentId = conditionalPayments.createConditionalPayment{value: 1 ether}(
            payee,
            conditionTypes,
            conditionData
        );

        // Fast forward time and fulfill first condition
        vm.warp(block.timestamp + 1 days + 1);
        conditionalPayments.fulfillCondition(paymentId, 0, "");

        // Check that payment is not executed yet (need all conditions)
        assertFalse(conditionalPayments.allConditionsFulfilled(paymentId));

        // Fulfill second condition (simplified)
        conditionalPayments.fulfillCondition(paymentId, 1, "proof");

        assertTrue(conditionalPayments.allConditionsFulfilled(paymentId));
    }

    function testFailInvalidConditionIndex() public {
        ConditionalPayments.ConditionType[] memory conditionTypes = new ConditionalPayments.ConditionType[](1);
        conditionTypes[0] = ConditionalPayments.ConditionType.TIME_BASED;

        bytes[] memory conditionData = new bytes[](1);
        conditionData[0] = abi.encode(block.timestamp + 1 days);

        vm.prank(payer);
        bytes32 paymentId = conditionalPayments.createConditionalPayment{value: 1 ether}(
            payee,
            conditionTypes,
            conditionData
        );

        vm.expectRevert("Invalid condition index");
        conditionalPayments.fulfillCondition(paymentId, 5, "");
    }
}
