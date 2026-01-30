// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BatchOperations {
    struct BatchResult {
        bool success;
        bytes returnData;
        string errorMessage;
    }

    event BatchExecuted(address indexed executor, uint256 operationCount, uint256 successCount);

    function batchCall(
        address[] memory targets,
        bytes[] memory callData
    ) external returns (BatchResult[] memory results) {
        require(targets.length == callData.length, "Array length mismatch");
        
        results = new BatchResult[](targets.length);
        uint256 successCount = 0;

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory returnData) = targets[i].call(callData[i]);
            
            results[i] = BatchResult({
                success: success,
                returnData: returnData,
                errorMessage: success ? "" : "Call failed"
            });

            if (success) successCount++;
        }

        emit BatchExecuted(msg.sender, targets.length, successCount);
    }

    function batchTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    ) external payable {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(msg.value >= totalAmount, "Insufficient funds");

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = payable(recipients[i]).call{value: amounts[i]}("");
            require(success, "Transfer failed");
        }
    }
}
