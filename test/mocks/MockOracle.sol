// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockOracle {
    mapping(string => uint256) public prices;
    mapping(string => uint256) public lastUpdated;

    event PriceUpdated(string symbol, uint256 price);

    function setPrice(string memory symbol, uint256 price) external {
        prices[symbol] = price;
        lastUpdated[symbol] = block.timestamp;
        emit PriceUpdated(symbol, price);
    }

    function getPrice(string memory symbol) external view returns (uint256, bool) {
        uint256 price = prices[symbol];
        bool valid = lastUpdated[symbol] > 0 && block.timestamp - lastUpdated[symbol] < 1 hours;
        return (price, valid);
    }

    function batchSetPrices(string[] memory symbols, uint256[] memory _prices) external {
        require(symbols.length == _prices.length, "Array length mismatch");
        
        for (uint256 i = 0; i < symbols.length; i++) {
            prices[symbols[i]] = _prices[i];
            lastUpdated[symbols[i]] = block.timestamp;
            emit PriceUpdated(symbols[i], _prices[i]);
        }
    }
}
