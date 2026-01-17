// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayErrors} from "./RecurPayErrors.sol";

/// @title PercentageMath
/// @author RecurPay Protocol
/// @notice Provides percentage calculation functions using basis points
library PercentageMath {
    /// @dev 100% represented as 10,000 basis points
    uint256 internal constant BASIS_POINTS_DIVISOR = 10_000;

    /// @notice Calculates the percentage of a value given in basis points
    /// @param amount The base value
    /// @param basisPoints The number of basis points (1 basis point = 0.01%)
    /// @return The calculated percentage of the amount
    /// @dev Reverts if basis points exceed the divisor
    function calculatePercentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        if (basisPoints > BASIS_POINTS_DIVISOR) {
            revert RecurPayErrors.FeeOverflow();
        }
        if (amount == 0 || basisPoints == 0) {
            return 0;
        }
        uint256 result;
        unchecked {
            result = (amount * basisPoints) / BASIS_POINTS_DIVISOR;
        }
        return result;
    }
}
