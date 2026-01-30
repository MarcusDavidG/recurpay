// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ConditionalPayments {
    enum ConditionType { TIME_BASED, ORACLE_BASED, MULTI_SIG, THRESHOLD }

    struct Condition {
        ConditionType conditionType;
        bytes conditionData;
        bool fulfilled;
    }

    struct ConditionalPayment {
        address payer;
        address payee;
        uint256 amount;
        Condition[] conditions;
        bool executed;
    }

    mapping(bytes32 => ConditionalPayment) public conditionalPayments;
    mapping(address => bytes32[]) public userConditionalPayments;

    event ConditionalPaymentCreated(bytes32 indexed paymentId, address payer, address payee);
    event ConditionFulfilled(bytes32 indexed paymentId, uint256 conditionIndex);
    event ConditionalPaymentExecuted(bytes32 indexed paymentId);

    function createConditionalPayment(
        address payee,
        ConditionType[] memory conditionTypes,
        bytes[] memory conditionData
    ) external payable returns (bytes32 paymentId) {
        require(conditionTypes.length == conditionData.length, "Array length mismatch");
        
        paymentId = keccak256(abi.encodePacked(msg.sender, payee, block.timestamp));
        
        ConditionalPayment storage payment = conditionalPayments[paymentId];
        payment.payer = msg.sender;
        payment.payee = payee;
        payment.amount = msg.value;
        payment.executed = false;

        for (uint256 i = 0; i < conditionTypes.length; i++) {
            payment.conditions.push(Condition({
                conditionType: conditionTypes[i],
                conditionData: conditionData[i],
                fulfilled: false
            }));
        }

        userConditionalPayments[msg.sender].push(paymentId);
        emit ConditionalPaymentCreated(paymentId, msg.sender, payee);
    }

    function fulfillCondition(bytes32 paymentId, uint256 conditionIndex, bytes memory proof) external {
        ConditionalPayment storage payment = conditionalPayments[paymentId];
        require(conditionIndex < payment.conditions.length, "Invalid condition index");
        require(!payment.conditions[conditionIndex].fulfilled, "Condition already fulfilled");

        // Simplified condition checking
        if (payment.conditions[conditionIndex].conditionType == ConditionType.TIME_BASED) {
            uint256 targetTime = abi.decode(payment.conditions[conditionIndex].conditionData, (uint256));
            require(block.timestamp >= targetTime, "Time condition not met");
        }

        payment.conditions[conditionIndex].fulfilled = true;
        emit ConditionFulfilled(paymentId, conditionIndex);

        // Check if all conditions are fulfilled
        if (allConditionsFulfilled(paymentId)) {
            executeConditionalPayment(paymentId);
        }
    }

    function executeConditionalPayment(bytes32 paymentId) internal {
        ConditionalPayment storage payment = conditionalPayments[paymentId];
        require(!payment.executed, "Already executed");
        require(allConditionsFulfilled(paymentId), "Not all conditions fulfilled");

        payment.executed = true;
        (bool success, ) = payable(payment.payee).call{value: payment.amount}("");
        require(success, "Payment failed");

        emit ConditionalPaymentExecuted(paymentId);
    }

    function allConditionsFulfilled(bytes32 paymentId) public view returns (bool) {
        ConditionalPayment storage payment = conditionalPayments[paymentId];
        for (uint256 i = 0; i < payment.conditions.length; i++) {
            if (!payment.conditions[i].fulfilled) {
                return false;
            }
        }
        return true;
    }
}
