// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentAggregator {
    struct AggregatedPayment {
        address[] recipients;
        uint256[] amounts;
        uint256 totalAmount;
        uint256 executionTime;
        bool executed;
    }

    mapping(bytes32 => AggregatedPayment) public aggregatedPayments;
    mapping(address => bytes32[]) public userAggregations;

    event PaymentAggregated(bytes32 indexed aggregationId, uint256 totalAmount, uint256 recipientCount);
    event AggregatedPaymentExecuted(bytes32 indexed aggregationId);

    function createAggregatedPayment(
        address[] memory recipients,
        uint256[] memory amounts,
        uint256 executionDelay
    ) external payable returns (bytes32 aggregationId) {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(msg.value >= totalAmount, "Insufficient payment");

        aggregationId = keccak256(abi.encodePacked(msg.sender, recipients, block.timestamp));
        
        aggregatedPayments[aggregationId] = AggregatedPayment({
            recipients: recipients,
            amounts: amounts,
            totalAmount: totalAmount,
            executionTime: block.timestamp + executionDelay,
            executed: false
        });

        userAggregations[msg.sender].push(aggregationId);
        emit PaymentAggregated(aggregationId, totalAmount, recipients.length);
    }

    function executeAggregatedPayment(bytes32 aggregationId) external {
        AggregatedPayment storage payment = aggregatedPayments[aggregationId];
        require(!payment.executed, "Already executed");
        require(block.timestamp >= payment.executionTime, "Not yet executable");

        payment.executed = true;

        for (uint256 i = 0; i < payment.recipients.length; i++) {
            (bool success, ) = payable(payment.recipients[i]).call{value: payment.amounts[i]}("");
            require(success, "Payment failed");
        }

        emit AggregatedPaymentExecuted(aggregationId);
    }

    function getAggregatedPayment(bytes32 aggregationId) external view returns (
        address[] memory recipients,
        uint256[] memory amounts,
        uint256 totalAmount,
        uint256 executionTime,
        bool executed
    ) {
        AggregatedPayment memory payment = aggregatedPayments[aggregationId];
        return (payment.recipients, payment.amounts, payment.totalAmount, payment.executionTime, payment.executed);
    }
}
