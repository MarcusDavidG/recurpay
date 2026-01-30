// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiTokenPaymentManager {
    struct TokenConfig {
        bool isSupported;
        uint256 decimals;
        address priceFeed;
        uint256 minAmount;
        uint256 maxAmount;
    }

    mapping(address => TokenConfig) public supportedTokens;
    address[] public tokenList;
    
    address public constant NATIVE_TOKEN = address(0);
    
    event TokenAdded(address indexed token, uint256 decimals);
    event TokenRemoved(address indexed token);
    event PaymentProcessed(address indexed token, uint256 amount, address indexed payer);

    function addSupportedToken(
        address token,
        uint256 decimals,
        address priceFeed,
        uint256 minAmount,
        uint256 maxAmount
    ) external {
        require(!supportedTokens[token].isSupported, "Token already supported");
        
        supportedTokens[token] = TokenConfig({
            isSupported: true,
            decimals: decimals,
            priceFeed: priceFeed,
            minAmount: minAmount,
            maxAmount: maxAmount
        });
        
        tokenList.push(token);
        emit TokenAdded(token, decimals);
    }

    function removeSupportedToken(address token) external {
        require(supportedTokens[token].isSupported, "Token not supported");
        
        supportedTokens[token].isSupported = false;
        
        // Remove from tokenList
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == token) {
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                break;
            }
        }
        
        emit TokenRemoved(token);
    }

    function processTokenPayment(
        address token,
        uint256 amount,
        address from,
        address to
    ) external returns (bool success) {
        require(supportedTokens[token].isSupported, "Token not supported");
        require(amount >= supportedTokens[token].minAmount, "Amount too low");
        require(amount <= supportedTokens[token].maxAmount, "Amount too high");

        if (token == NATIVE_TOKEN) {
            require(msg.value == amount, "Incorrect ETH amount");
            (success, ) = payable(to).call{value: amount}("");
        } else {
            success = IERC20(token).transferFrom(from, to, amount);
        }

        require(success, "Payment failed");
        emit PaymentProcessed(token, amount, from);
    }

    function convertToUSD(address token, uint256 amount) external view returns (uint256 usdAmount) {
        TokenConfig memory config = supportedTokens[token];
        require(config.isSupported, "Token not supported");
        require(config.priceFeed != address(0), "Price feed not set");

        // This would integrate with Chainlink or another oracle
        // For now, returning a placeholder
        return amount; // Simplified - would use actual price feed
    }

    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token].isSupported;
    }

    function getSupportedTokens() external view returns (address[] memory) {
        return tokenList;
    }

    function getTokenConfig(address token) external view returns (TokenConfig memory) {
        return supportedTokens[token];
    }

    function calculateEquivalentAmount(
        address fromToken,
        address toToken,
        uint256 amount
    ) external view returns (uint256) {
        require(supportedTokens[fromToken].isSupported, "From token not supported");
        require(supportedTokens[toToken].isSupported, "To token not supported");
        
        // Simplified conversion - would use actual price feeds
        return amount;
    }
}
