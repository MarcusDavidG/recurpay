// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentScheduler {
    struct ScheduledPayment {
        address payer;
        address payee;
        uint256 amount;
        uint256 executeAt;
        uint256 interval;
        uint256 maxExecutions;
        uint256 executionCount;
        bool active;
    }

    mapping(bytes32 => ScheduledPayment) public scheduledPayments;
    mapping(address => bytes32[]) public userScheduledPayments;

    event PaymentScheduled(bytes32 indexed paymentId, address payer, address payee, uint256 executeAt);
    event PaymentExecuted(bytes32 indexed paymentId, uint256 executionCount);

    function schedulePayment(
        address payee,
        uint256 executeAt,
        uint256 interval,
        uint256 maxExecutions
    ) external payable returns (bytes32 paymentId) {
        paymentId = keccak256(abi.encodePacked(msg.sender, payee, executeAt, block.timestamp));
        
        scheduledPayments[paymentId] = ScheduledPayment({
            payer: msg.sender,
            payee: payee,
            amount: msg.value,
            executeAt: executeAt,
            interval: interval,
            maxExecutions: maxExecutions,
            executionCount: 0,
            active: true
        });

        userScheduledPayments[msg.sender].push(paymentId);
        emit PaymentScheduled(paymentId, msg.sender, payee, executeAt);
    }

    function executeScheduledPayment(bytes32 paymentId) external {
        ScheduledPayment storage payment = scheduledPayments[paymentId];
        require(payment.active, "Payment not active");
        require(block.timestamp >= payment.executeAt, "Not yet executable");
        require(payment.executionCount < payment.maxExecutions, "Max executions reached");

        payment.executionCount++;
        payment.executeAt += payment.interval;

        if (payment.executionCount >= payment.maxExecutions) {
            payment.active = false;
        }

        (bool success, ) = payable(payment.payee).call{value: payment.amount}("");
        require(success, "Payment failed");

        emit PaymentExecuted(paymentId, payment.executionCount);
    }

    function cancelScheduledPayment(bytes32 paymentId) external {
        ScheduledPayment storage payment = scheduledPayments[paymentId];
        require(payment.payer == msg.sender, "Not payer");
        
        payment.active = false;
        uint256 refund = payment.amount * (payment.maxExecutions - payment.executionCount);
        
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        require(success, "Refund failed");
    }
}
