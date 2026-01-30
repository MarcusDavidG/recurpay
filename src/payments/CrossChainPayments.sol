// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CrossChainPayments {
    struct CrossChainPayment {
        address sender;
        address recipient;
        uint256 amount;
        uint256 targetChain;
        bytes32 messageHash;
        bool processed;
    }

    mapping(bytes32 => CrossChainPayment) public crossChainPayments;
    mapping(uint256 => bool) public supportedChains;

    event CrossChainPaymentInitiated(bytes32 indexed paymentId, uint256 targetChain, uint256 amount);
    event CrossChainPaymentProcessed(bytes32 indexed paymentId);

    function initiateCrossChainPayment(
        address recipient,
        uint256 targetChain
    ) external payable returns (bytes32 paymentId) {
        require(supportedChains[targetChain], "Chain not supported");
        
        paymentId = keccak256(abi.encodePacked(msg.sender, recipient, targetChain, block.timestamp));
        
        crossChainPayments[paymentId] = CrossChainPayment({
            sender: msg.sender,
            recipient: recipient,
            amount: msg.value,
            targetChain: targetChain,
            messageHash: keccak256(abi.encodePacked(paymentId, recipient, msg.value)),
            processed: false
        });

        emit CrossChainPaymentInitiated(paymentId, targetChain, msg.value);
    }

    function processCrossChainPayment(bytes32 paymentId, bytes memory proof) external {
        CrossChainPayment storage payment = crossChainPayments[paymentId];
        require(!payment.processed, "Already processed");
        
        // Simplified proof verification
        require(keccak256(proof) != bytes32(0), "Invalid proof");
        
        payment.processed = true;
        (bool success, ) = payable(payment.recipient).call{value: payment.amount}("");
        require(success, "Transfer failed");

        emit CrossChainPaymentProcessed(paymentId);
    }

    function addSupportedChain(uint256 chainId) external {
        supportedChains[chainId] = true;
    }
}
