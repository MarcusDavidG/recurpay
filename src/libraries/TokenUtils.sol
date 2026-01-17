// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {RecurPayErrors} from "./RecurPayErrors.sol";

/// @title TokenUtils
/// @author RecurPay Protocol
/// @notice Provides safe token transfer utility functions
library TokenUtils {
    using SafeERC20 for IERC20;

    /// @notice Safely transfers ERC20 tokens
    /// @param token The token to transfer
    /// @param to The recipient of the transfer
    /// @param amount The amount to transfer
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        token.safeTransfer(to, amount);
    }

    /// @notice Safely transfers ERC20 tokens from a specific address
    /// @param token The token to transfer
    /// @param from The address to transfer from
    /// @param to The recipient of the transfer
    /// @param amount The amount to transfer
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        token.safeTransferFrom(from, to, amount);
    }

    /// @notice Safely transfers ETH
    /// @param to The recipient of the transfer
    /// @param amount The amount to transfer
    function safeTransferETH(address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert RecurPayErrors.ETHTransferFailed();
        }
    }
}
