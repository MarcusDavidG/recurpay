# RecurPay Protocol

<div align="center">

![Base](https://img.shields.io/badge/Base-0052FF?style=for-the-badge&logo=coinbase&logoColor=white)
![Solidity](https://img.shields.io/badge/Solidity-363636?style=for-the-badge&logo=solidity&logoColor=white)
![Foundry](https://img.shields.io/badge/Foundry-1C1C1C?style=for-the-badge&logo=ethereum&logoColor=white)

**Trustless Onchain Recurring Payments for Base**

[Documentation](#documentation) • [Contracts](#smart-contracts) • [Getting Started](#getting-started) • [Contributing](#contributing)

</div>

---

## Overview

RecurPay is a decentralized recurring payment protocol built on **Base**, enabling trustless subscription infrastructure for the creator economy. It allows creators to set up subscription tiers while giving subscribers full control over their payment approvals.

### Key Features

- **Creator Subscription Tiers** — Flexible pricing plans with customizable benefits
- **Automated Recurring Pulls** — Trustless payment execution with pre-approved allowances
- **Grace Periods & Pause** — Subscriber-friendly controls for payment management
- **Revenue Analytics** — Onchain tracking of subscription metrics
- **Non-Custodial** — Creators receive payments directly to their vaults

---

## Smart Contracts

| Contract | Description | Address |
|----------|-------------|---------|
| `SubscriptionFactory` | Creates and manages subscription plans | TBD |
| `PaymentProcessor` | Executes recurring payment pulls | TBD |
| `CreatorVault` | Revenue management for creators | TBD |
| `SubscriberRegistry` | Tracks active subscriptions | TBD |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         RecurPay Protocol                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────┐         ┌──────────────────┐             │
│   │  Subscription    │         │    Payment       │             │
│   │    Factory       │────────▶│   Processor      │             │
│   └──────────────────┘         └────────┬─────────┘             │
│            │                            │                        │
│            │                            │                        │
│            ▼                            ▼                        │
│   ┌──────────────────┐         ┌──────────────────┐             │
│   │   Subscriber     │         │    Creator       │             │
│   │    Registry      │◀───────▶│     Vault        │             │
│   └──────────────────┘         └──────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) >= 18.0.0

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/recurpay-protocol.git
cd recurpay-protocol

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### Configuration

Copy the environment template and configure your settings:

```bash
cp .env.example .env
```

Required environment variables:

```env
# Base Mainnet RPC
BASE_RPC_URL=https://mainnet.base.org

# Deployer private key (use a dedicated deployment wallet)
PRIVATE_KEY=

# BaseScan API key for verification
BASESCAN_API_KEY=
```

---

## Development

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test
forge test --match-test testSubscriptionCreation
```

### Format

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

---

## Deployment

### Base Mainnet

```bash
forge script script/Deploy.s.sol:DeployRecurPay \
    --rpc-url $BASE_RPC_URL \
    --broadcast \
    --verify
```

### Contract Verification

Contracts are automatically verified during deployment. For manual verification:

```bash
forge verify-contract <CONTRACT_ADDRESS> src/SubscriptionFactory.sol:SubscriptionFactory \
    --chain base \
    --etherscan-api-key $BASESCAN_API_KEY
```

---

## Documentation

- [Protocol Specification](./docs/SPECIFICATION.md)
- [Integration Guide](./docs/INTEGRATION.md)
- [Security Considerations](./docs/SECURITY.md)

---

## Security

RecurPay Protocol has not yet been audited. Use at your own risk.

If you discover a security vulnerability, please report it via [security@example.com](mailto:security@example.com).

---

## Contributing

We welcome contributions! Please see our [Contributing Guide](./CONTRIBUTING.md) for details.

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

<div align="center">

**Built with 💙 on Base**

[Base](https://base.org) • [Coinbase](https://coinbase.com)

</div>
