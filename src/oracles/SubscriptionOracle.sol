// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionOracle {
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        address updater;
        bool valid;
    }

    mapping(string => PriceData) public priceFeeds;
    mapping(address => bool) public authorizedUpdaters;
    mapping(string => uint256) public priceDeviationThreshold;

    uint256 public constant MAX_PRICE_AGE = 1 hours;
    uint256 public constant DEFAULT_DEVIATION_THRESHOLD = 500; // 5%

    event PriceUpdated(string indexed symbol, uint256 price, address updater);
    event UpdaterAuthorized(address updater);

    modifier onlyAuthorized() {
        require(authorizedUpdaters[msg.sender], "Not authorized");
        _;
    }

    function authorizeUpdater(address updater) external {
        authorizedUpdaters[updater] = true;
        emit UpdaterAuthorized(updater);
    }

    function updatePrice(string memory symbol, uint256 price) external onlyAuthorized {
        PriceData storage priceData = priceFeeds[symbol];
        
        // Check for price deviation if previous price exists
        if (priceData.valid && priceData.timestamp > 0) {
            uint256 threshold = priceDeviationThreshold[symbol];
            if (threshold == 0) threshold = DEFAULT_DEVIATION_THRESHOLD;
            
            uint256 deviation = price > priceData.price 
                ? ((price - priceData.price) * 10000) / priceData.price
                : ((priceData.price - price) * 10000) / priceData.price;
                
            require(deviation <= threshold, "Price deviation too high");
        }

        priceData.price = price;
        priceData.timestamp = block.timestamp;
        priceData.updater = msg.sender;
        priceData.valid = true;

        emit PriceUpdated(symbol, price, msg.sender);
    }

    function getPrice(string memory symbol) external view returns (uint256 price, bool valid) {
        PriceData memory priceData = priceFeeds[symbol];
        
        valid = priceData.valid && 
                (block.timestamp - priceData.timestamp) <= MAX_PRICE_AGE;
        
        return (priceData.price, valid);
    }

    function setDeviationThreshold(string memory symbol, uint256 threshold) external {
        require(threshold <= 5000, "Threshold too high"); // Max 50%
        priceDeviationThreshold[symbol] = threshold;
    }

    function isPriceStale(string memory symbol) external view returns (bool) {
        PriceData memory priceData = priceFeeds[symbol];
        return (block.timestamp - priceData.timestamp) > MAX_PRICE_AGE;
    }

    function getLastUpdate(string memory symbol) external view returns (uint256) {
        return priceFeeds[symbol].timestamp;
    }
}
