// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockPaymentProcessor {
    mapping(bytes32 => bool) public processedPayments;
    mapping(address => uint256) public balances;
    
    bool public shouldFail;
    uint256 public processingFee = 100; // 1%

    event MockPaymentProcessed(bytes32 subscriptionId, uint256 amount);
    event MockPaymentFailed(bytes32 subscriptionId, string reason);

    function setFailureMode(bool _shouldFail) external {
        shouldFail = _shouldFail;
    }

    function processPayment(bytes32 subscriptionId, uint256 amount) external returns (bool) {
        if (shouldFail) {
            emit MockPaymentFailed(subscriptionId, "Mock failure");
            return false;
        }

        processedPayments[subscriptionId] = true;
        uint256 fee = (amount * processingFee) / 10000;
        balances[msg.sender] += amount - fee;
        
        emit MockPaymentProcessed(subscriptionId, amount);
        return true;
    }

    function isPaymentProcessed(bytes32 subscriptionId) external view returns (bool) {
        return processedPayments[subscriptionId];
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function setProcessingFee(uint256 _fee) external {
        processingFee = _fee;
    }
}
