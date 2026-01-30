#!/bin/bash

# RecurPay Protocol Deployment Script
echo "Deploying RecurPay Protocol to Production..."

# Check environment variables
if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY environment variable not set"
    exit 1
fi

if [ -z "$BASE_RPC_URL" ]; then
    echo "Error: BASE_RPC_URL environment variable not set"
    exit 1
fi

# Deploy to Base Mainnet
echo "Deploying to Base Mainnet..."
forge script script/DeployComplete.s.sol:DeployComplete \
    --rpc-url $BASE_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY

echo "Deployment completed!"
echo "Contracts deployed and verified on BaseScan"
echo "RecurPay Protocol is now live on Base!"
