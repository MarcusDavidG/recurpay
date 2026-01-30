// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentSplitter {
    struct Split {
        address recipient;
        uint256 percentage;
    }

    mapping(address => Split[]) public creatorSplits;
    mapping(address => uint256) public totalPercentages;

    event SplitAdded(address indexed creator, address recipient, uint256 percentage);

    function addSplit(address recipient, uint256 percentage) external {
        require(totalPercentages[msg.sender] + percentage <= 10000, "Exceeds 100%");
        
        creatorSplits[msg.sender].push(Split(recipient, percentage));
        totalPercentages[msg.sender] += percentage;

        emit SplitAdded(msg.sender, recipient, percentage);
    }

    function splitPayment(address creator, uint256 amount) external returns (uint256 remaining) {
        Split[] memory splits = creatorSplits[creator];
        remaining = amount;

        for (uint256 i = 0; i < splits.length; i++) {
            uint256 splitAmount = (amount * splits[i].percentage) / 10000;
            remaining -= splitAmount;
            (bool success, ) = payable(splits[i].recipient).call{value: splitAmount}("");
            require(success, "Split transfer failed");
        }
    }
}
