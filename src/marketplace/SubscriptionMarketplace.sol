// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionMarketplace {
    struct Listing {
        address creator;
        string title;
        string description;
        uint256 price;
        string category;
        uint256 rating;
        uint256 reviewCount;
        bool active;
        uint256 subscriberCount;
    }

    struct Review {
        address reviewer;
        uint256 rating;
        string comment;
        uint256 timestamp;
    }

    mapping(bytes32 => Listing) public listings;
    mapping(bytes32 => Review[]) public listingReviews;
    mapping(string => bytes32[]) public categoryListings;
    mapping(address => bytes32[]) public creatorListings;

    event ListingCreated(bytes32 indexed listingId, address indexed creator, string title);
    event ReviewAdded(bytes32 indexed listingId, address indexed reviewer, uint256 rating);

    function createListing(
        string memory title,
        string memory description,
        uint256 price,
        string memory category
    ) external returns (bytes32 listingId) {
        listingId = keccak256(abi.encodePacked(msg.sender, title, block.timestamp));
        
        listings[listingId] = Listing({
            creator: msg.sender,
            title: title,
            description: description,
            price: price,
            category: category,
            rating: 0,
            reviewCount: 0,
            active: true,
            subscriberCount: 0
        });

        categoryListings[category].push(listingId);
        creatorListings[msg.sender].push(listingId);

        emit ListingCreated(listingId, msg.sender, title);
    }

    function addReview(bytes32 listingId, uint256 rating, string memory comment) external {
        require(rating >= 1 && rating <= 5, "Invalid rating");
        
        listingReviews[listingId].push(Review({
            reviewer: msg.sender,
            rating: rating,
            comment: comment,
            timestamp: block.timestamp
        }));

        // Update average rating
        Listing storage listing = listings[listingId];
        listing.rating = ((listing.rating * listing.reviewCount) + rating) / (listing.reviewCount + 1);
        listing.reviewCount++;

        emit ReviewAdded(listingId, msg.sender, rating);
    }

    function getListing(bytes32 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    function getListingsByCategory(string memory category) external view returns (bytes32[] memory) {
        return categoryListings[category];
    }
}
