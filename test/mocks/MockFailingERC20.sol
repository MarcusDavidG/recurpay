// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockFailingERC20
/// @author RecurPay Protocol
/// @notice Mock ERC20 that can be configured to fail transfers
contract MockFailingERC20 is ERC20 {
    bool public shouldFailTransfer;
    bool public shouldFailTransferFrom;

    constructor() ERC20("Failing Token", "FAIL") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setShouldFailTransfer(bool fail) external {
        shouldFailTransfer = fail;
    }

    function setShouldFailTransferFrom(bool fail) external {
        shouldFailTransferFrom = fail;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (shouldFailTransfer) {
            return false;
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (shouldFailTransferFrom) {
            return false;
        }
        return super.transferFrom(from, to, amount);
    }
}
