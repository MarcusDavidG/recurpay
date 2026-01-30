// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentEscrow {
    struct EscrowDeposit {
        address payer;
        address payee;
        uint256 amount;
        uint256 releaseTime;
        bool released;
        bool disputed;
    }

    mapping(bytes32 => EscrowDeposit) public deposits;
    mapping(address => bytes32[]) public userDeposits;

    event DepositCreated(bytes32 indexed depositId, address payer, address payee, uint256 amount);
    event DepositReleased(bytes32 indexed depositId);

    function createDeposit(address payee, uint256 releaseDelay) external payable returns (bytes32 depositId) {
        depositId = keccak256(abi.encodePacked(msg.sender, payee, block.timestamp));
        
        deposits[depositId] = EscrowDeposit({
            payer: msg.sender,
            payee: payee,
            amount: msg.value,
            releaseTime: block.timestamp + releaseDelay,
            released: false,
            disputed: false
        });

        userDeposits[msg.sender].push(depositId);
        emit DepositCreated(depositId, msg.sender, payee, msg.value);
    }

    function releaseDeposit(bytes32 depositId) external {
        EscrowDeposit storage deposit = deposits[depositId];
        require(block.timestamp >= deposit.releaseTime, "Not yet releasable");
        require(!deposit.released, "Already released");
        require(!deposit.disputed, "Deposit disputed");

        deposit.released = true;
        (bool success, ) = payable(deposit.payee).call{value: deposit.amount}("");
        require(success, "Transfer failed");

        emit DepositReleased(depositId);
    }
}
