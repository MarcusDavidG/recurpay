// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionBundleManager {
    struct Bundle {
        string name;
        address[] creators;
        uint256[] subscriptionIds;
        uint256 bundlePrice;
        uint256 individualPrice;
        uint256 discount;
        bool active;
        uint256 maxSubscribers;
        uint256 currentSubscribers;
        uint256 validUntil;
    }

    struct BundleSubscription {
        bytes32 bundleId;
        address subscriber;
        uint256 startTime;
        uint256 nextPayment;
        bool active;
        uint256 amountPaid;
    }

    mapping(bytes32 => Bundle) public bundles;
    mapping(bytes32 => BundleSubscription) public bundleSubscriptions;
    mapping(address => bytes32[]) public userBundles;
    mapping(address => bytes32[]) public creatorBundles;
    
    uint256 public bundleCounter;

    event BundleCreated(bytes32 indexed bundleId, string name, uint256 price, uint256 discount);
    event BundleSubscribed(bytes32 indexed bundleId, address indexed subscriber);
    event BundleUnsubscribed(bytes32 indexed bundleId, address indexed subscriber);

    function createBundle(
        string memory name,
        address[] memory creators,
        uint256[] memory subscriptionIds,
        uint256 bundlePrice,
        uint256 discount,
        uint256 maxSubscribers,
        uint256 validUntil
    ) external returns (bytes32 bundleId) {
        require(creators.length == subscriptionIds.length, "Array length mismatch");
        require(creators.length > 1, "Bundle needs multiple creators");
        require(discount <= 5000, "Discount too high"); // Max 50%

        bundleId = keccak256(abi.encodePacked(
            name,
            creators,
            block.timestamp,
            bundleCounter++
        ));

        uint256 individualPrice = calculateIndividualPrice(creators, subscriptionIds);

        bundles[bundleId] = Bundle({
            name: name,
            creators: creators,
            subscriptionIds: subscriptionIds,
            bundlePrice: bundlePrice,
            individualPrice: individualPrice,
            discount: discount,
            active: true,
            maxSubscribers: maxSubscribers,
            currentSubscribers: 0,
            validUntil: validUntil
        });

        // Add to each creator's bundle list
        for (uint256 i = 0; i < creators.length; i++) {
            creatorBundles[creators[i]].push(bundleId);
        }

        emit BundleCreated(bundleId, name, bundlePrice, discount);
    }

    function subscribeToBundle(bytes32 bundleId) external payable {
        Bundle storage bundle = bundles[bundleId];
        require(bundle.active, "Bundle not active");
        require(bundle.currentSubscribers < bundle.maxSubscribers, "Bundle full");
        require(block.timestamp <= bundle.validUntil, "Bundle expired");
        require(msg.value >= bundle.bundlePrice, "Insufficient payment");

        bytes32 subscriptionId = keccak256(abi.encodePacked(
            bundleId,
            msg.sender,
            block.timestamp
        ));

        bundleSubscriptions[subscriptionId] = BundleSubscription({
            bundleId: bundleId,
            subscriber: msg.sender,
            startTime: block.timestamp,
            nextPayment: block.timestamp + 30 days,
            active: true,
            amountPaid: msg.value
        });

        bundle.currentSubscribers++;
        userBundles[msg.sender].push(bundleId);

        // Distribute payment to creators
        distributePayment(bundleId, msg.value);

        emit BundleSubscribed(bundleId, msg.sender);
    }

    function unsubscribeFromBundle(bytes32 subscriptionId) external {
        BundleSubscription storage subscription = bundleSubscriptions[subscriptionId];
        require(subscription.subscriber == msg.sender, "Not your subscription");
        require(subscription.active, "Already unsubscribed");

        subscription.active = false;
        bundles[subscription.bundleId].currentSubscribers--;

        emit BundleUnsubscribed(subscription.bundleId, msg.sender);
    }

    function calculateIndividualPrice(
        address[] memory creators,
        uint256[] memory subscriptionIds
    ) internal pure returns (uint256 total) {
        // Simplified calculation - would integrate with actual subscription pricing
        total = creators.length * 1e18; // 1 ETH per subscription
    }

    function distributePayment(bytes32 bundleId, uint256 amount) internal {
        Bundle memory bundle = bundles[bundleId];
        uint256 amountPerCreator = amount / bundle.creators.length;

        for (uint256 i = 0; i < bundle.creators.length; i++) {
            (bool success, ) = payable(bundle.creators[i]).call{value: amountPerCreator}("");
            require(success, "Payment distribution failed");
        }
    }

    function getBundleDetails(bytes32 bundleId) external view returns (Bundle memory) {
        return bundles[bundleId];
    }

    function getUserBundles(address user) external view returns (bytes32[] memory) {
        return userBundles[user];
    }

    function getCreatorBundles(address creator) external view returns (bytes32[] memory) {
        return creatorBundles[creator];
    }

    function calculateSavings(bytes32 bundleId) external view returns (uint256) {
        Bundle memory bundle = bundles[bundleId];
        return bundle.individualPrice - bundle.bundlePrice;
    }

    function isBundleActive(bytes32 bundleId) external view returns (bool) {
        Bundle memory bundle = bundles[bundleId];
        return bundle.active && block.timestamp <= bundle.validUntil;
    }

    function deactivateBundle(bytes32 bundleId) external {
        Bundle storage bundle = bundles[bundleId];
        
        // Check if sender is one of the creators
        bool isCreator = false;
        for (uint256 i = 0; i < bundle.creators.length; i++) {
            if (bundle.creators[i] == msg.sender) {
                isCreator = true;
                break;
            }
        }
        require(isCreator, "Not a bundle creator");

        bundle.active = false;
    }
}
