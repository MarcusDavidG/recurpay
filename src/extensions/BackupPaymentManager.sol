// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BackupPaymentManager {
    struct PaymentMethod {
        address tokenAddress;
        uint256 allowance;
        bool active;
        uint256 priority;
        uint256 lastUsed;
        string methodType; // "token", "native", "vault"
    }

    struct BackupConfig {
        bool autoFallback;
        uint256 maxRetries;
        uint256 retryDelay;
        bool requireConfirmation;
    }

    mapping(address => PaymentMethod[]) public userPaymentMethods;
    mapping(address => BackupConfig) public backupConfigs;
    mapping(bytes32 => uint256) public failedPaymentAttempts;
    
    event PaymentMethodAdded(address indexed user, address indexed token, uint256 priority);
    event PaymentMethodRemoved(address indexed user, uint256 index);
    event BackupPaymentUsed(address indexed user, bytes32 indexed paymentId, uint256 methodIndex);
    event PaymentFallbackFailed(address indexed user, bytes32 indexed paymentId);

    function addPaymentMethod(
        address tokenAddress,
        uint256 allowance,
        uint256 priority,
        string memory methodType
    ) external {
        userPaymentMethods[msg.sender].push(PaymentMethod({
            tokenAddress: tokenAddress,
            allowance: allowance,
            active: true,
            priority: priority,
            lastUsed: 0,
            methodType: methodType
        }));

        // Sort by priority
        sortPaymentMethods(msg.sender);

        emit PaymentMethodAdded(msg.sender, tokenAddress, priority);
    }

    function removePaymentMethod(uint256 index) external {
        require(index < userPaymentMethods[msg.sender].length, "Invalid index");
        
        PaymentMethod[] storage methods = userPaymentMethods[msg.sender];
        
        // Move last element to deleted spot and remove last element
        methods[index] = methods[methods.length - 1];
        methods.pop();

        emit PaymentMethodRemoved(msg.sender, index);
    }

    function setBackupConfig(
        bool autoFallback,
        uint256 maxRetries,
        uint256 retryDelay,
        bool requireConfirmation
    ) external {
        backupConfigs[msg.sender] = BackupConfig({
            autoFallback: autoFallback,
            maxRetries: maxRetries,
            retryDelay: retryDelay,
            requireConfirmation: requireConfirmation
        });
    }

    function processPaymentWithBackup(
        address user,
        uint256 amount,
        bytes32 paymentId
    ) external returns (bool success, uint256 methodUsed) {
        PaymentMethod[] storage methods = userPaymentMethods[user];
        BackupConfig memory config = backupConfigs[user];
        
        require(methods.length > 0, "No payment methods");
        
        uint256 attempts = failedPaymentAttempts[paymentId];
        require(attempts < config.maxRetries, "Max retries exceeded");

        // Try each payment method in priority order
        for (uint256 i = 0; i < methods.length; i++) {
            if (!methods[i].active) continue;

            if (tryPaymentMethod(user, i, amount)) {
                methods[i].lastUsed = block.timestamp;
                emit BackupPaymentUsed(user, paymentId, i);
                return (true, i);
            }
        }

        // All methods failed
        failedPaymentAttempts[paymentId]++;
        emit PaymentFallbackFailed(user, paymentId);
        return (false, 0);
    }

    function tryPaymentMethod(
        address user,
        uint256 methodIndex,
        uint256 amount
    ) internal returns (bool success) {
        PaymentMethod storage method = userPaymentMethods[user][methodIndex];
        
        if (keccak256(bytes(method.methodType)) == keccak256(bytes("native"))) {
            // Try native ETH payment (simplified)
            return user.balance >= amount;
        } else if (keccak256(bytes(method.methodType)) == keccak256(bytes("token"))) {
            // Try ERC20 token payment
            return checkTokenBalance(user, method.tokenAddress, amount);
        }
        
        return false;
    }

    function checkTokenBalance(address user, address token, uint256 amount) internal view returns (bool) {
        // Simplified token balance check
        // In real implementation, would use IERC20(token).balanceOf(user)
        return true; // Placeholder
    }

    function sortPaymentMethods(address user) internal {
        PaymentMethod[] storage methods = userPaymentMethods[user];
        
        // Simple bubble sort by priority (higher priority first)
        for (uint256 i = 0; i < methods.length; i++) {
            for (uint256 j = i + 1; j < methods.length; j++) {
                if (methods[i].priority < methods[j].priority) {
                    PaymentMethod memory temp = methods[i];
                    methods[i] = methods[j];
                    methods[j] = temp;
                }
            }
        }
    }

    function updatePaymentMethodPriority(uint256 index, uint256 newPriority) external {
        require(index < userPaymentMethods[msg.sender].length, "Invalid index");
        
        userPaymentMethods[msg.sender][index].priority = newPriority;
        sortPaymentMethods(msg.sender);
    }

    function deactivatePaymentMethod(uint256 index) external {
        require(index < userPaymentMethods[msg.sender].length, "Invalid index");
        userPaymentMethods[msg.sender][index].active = false;
    }

    function activatePaymentMethod(uint256 index) external {
        require(index < userPaymentMethods[msg.sender].length, "Invalid index");
        userPaymentMethods[msg.sender][index].active = true;
    }

    function getUserPaymentMethods(address user) external view returns (PaymentMethod[] memory) {
        return userPaymentMethods[user];
    }

    function getActivePaymentMethods(address user) external view returns (PaymentMethod[] memory active) {
        PaymentMethod[] memory allMethods = userPaymentMethods[user];
        uint256 activeCount = 0;

        // Count active methods
        for (uint256 i = 0; i < allMethods.length; i++) {
            if (allMethods[i].active) {
                activeCount++;
            }
        }

        // Create array of active methods
        active = new PaymentMethod[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allMethods.length; i++) {
            if (allMethods[i].active) {
                active[index] = allMethods[i];
                index++;
            }
        }
    }

    function getBackupConfig(address user) external view returns (BackupConfig memory) {
        return backupConfigs[user];
    }

    function getFailedAttempts(bytes32 paymentId) external view returns (uint256) {
        return failedPaymentAttempts[paymentId];
    }
}
