# Integration Guide

## Quick Start

### Prerequisites
- Node.js >= 18.0.0
- Foundry toolkit
- Base network access
- Supported tokens (USDC, WETH, etc.)

### Installation

```bash
npm install @recurpay/sdk
# or
yarn add @recurpay/sdk
```

### Basic Setup

```javascript
import { RecurPaySDK } from '@recurpay/sdk';

const recurpay = new RecurPaySDK({
  network: 'base-mainnet',
  privateKey: process.env.PRIVATE_KEY,
  rpcUrl: process.env.BASE_RPC_URL
});
```

## Creator Integration

### Creating Subscription Plans

```javascript
// Create a basic subscription plan
const plan = await recurpay.createPlan({
  name: "Premium Content",
  description: "Access to exclusive content",
  price: "10.00", // USDC
  billingPeriod: 30, // days
  token: "USDC",
  maxSubscribers: 1000
});

console.log(`Plan created with ID: ${plan.id}`);
```

### Managing Subscriptions

```javascript
// Get plan statistics
const stats = await recurpay.getPlanStats(planId);
console.log(`Active subscribers: ${stats.activeSubscribers}`);
console.log(`Monthly revenue: ${stats.monthlyRevenue}`);

// Update plan pricing
await recurpay.updatePlan(planId, {
  price: "12.00"
});
```

### Revenue Management

```javascript
// Check available balance
const balance = await recurpay.getCreatorBalance();
console.log(`Available: ${balance.available} USDC`);

// Withdraw funds
const tx = await recurpay.withdraw({
  token: "USDC",
  amount: "100.00",
  recipient: "0x..." // optional, defaults to creator address
});
```

## Subscriber Integration

### Subscribing to Plans

```javascript
// Subscribe to a plan
const subscription = await recurpay.subscribe({
  planId: planId,
  subscriber: userAddress,
  paymentToken: "USDC"
});

console.log(`Subscription ID: ${subscription.id}`);
```

### Managing Subscriptions

```javascript
// Pause subscription
await recurpay.pauseSubscription(subscriptionId, {
  duration: 7 // days
});

// Resume subscription
await recurpay.resumeSubscription(subscriptionId);

// Cancel subscription
await recurpay.cancelSubscription(subscriptionId);
```

### Payment Methods

```javascript
// Add backup payment method
await recurpay.addPaymentMethod({
  token: "WETH",
  priority: 2
});

// Set payment preferences
await recurpay.setPaymentPreferences({
  autoRetry: true,
  maxRetries: 3,
  retryInterval: 24 // hours
});
```

## Advanced Features

### Discount Codes

```javascript
// Create discount code
const discount = await recurpay.createDiscount({
  code: "SAVE20",
  percentage: 20,
  maxUses: 100,
  validUntil: Date.now() + (30 * 24 * 60 * 60 * 1000) // 30 days
});

// Apply discount
const discountedPrice = await recurpay.applyDiscount(
  "SAVE20",
  userAddress,
  originalPrice
);
```

### Referral System

```javascript
// Activate referrer
await recurpay.activateReferrer();

// Register referral
await recurpay.registerReferral(referrerAddress);

// Get referral stats
const stats = await recurpay.getReferralStats(referrerAddress);
console.log(`Total referred: ${stats.totalReferred}`);
console.log(`Total earned: ${stats.totalEarned}`);
```

### Subscription Tiers

```javascript
// Create multiple tiers
const tiers = await Promise.all([
  recurpay.createTier({
    name: "Basic",
    price: "5.00",
    features: ["Feature 1", "Feature 2"]
  }),
  recurpay.createTier({
    name: "Premium",
    price: "10.00",
    features: ["Feature 1", "Feature 2", "Feature 3"]
  })
]);
```

## Webhooks

### Setting Up Webhooks

```javascript
// Register webhook endpoint
await recurpay.registerWebhook({
  url: "https://your-app.com/webhooks/recurpay",
  events: [
    "subscription.created",
    "payment.processed",
    "subscription.cancelled"
  ]
});
```

### Webhook Handler Example

```javascript
// Express.js webhook handler
app.post('/webhooks/recurpay', (req, res) => {
  const { event, data } = req.body;
  
  switch (event) {
    case 'subscription.created':
      console.log(`New subscription: ${data.subscriptionId}`);
      // Grant access to content
      break;
      
    case 'payment.processed':
      console.log(`Payment processed: ${data.amount}`);
      // Update user credits
      break;
      
    case 'subscription.cancelled':
      console.log(`Subscription cancelled: ${data.subscriptionId}`);
      // Revoke access
      break;
  }
  
  res.status(200).send('OK');
});
```

## Analytics Integration

### Revenue Analytics

```javascript
// Get revenue breakdown
const analytics = await recurpay.getAnalytics({
  timeframe: "30d",
  metrics: ["revenue", "subscribers", "churn"]
});

console.log(`Revenue: ${analytics.revenue}`);
console.log(`New subscribers: ${analytics.newSubscribers}`);
console.log(`Churn rate: ${analytics.churnRate}%`);
```

### Custom Metrics

```javascript
// Track custom events
await recurpay.trackEvent({
  event: "content_viewed",
  userId: userAddress,
  metadata: {
    contentId: "article-123",
    duration: 300 // seconds
  }
});
```

## Error Handling

### Common Error Patterns

```javascript
try {
  await recurpay.processPayment(subscriptionId);
} catch (error) {
  switch (error.code) {
    case 'INSUFFICIENT_BALANCE':
      // Handle insufficient balance
      await notifyUser("Please top up your balance");
      break;
      
    case 'SUBSCRIPTION_PAUSED':
      // Handle paused subscription
      await offerResumeOption(subscriptionId);
      break;
      
    case 'RATE_LIMITED':
      // Handle rate limiting
      await delay(error.retryAfter);
      break;
      
    default:
      console.error('Unexpected error:', error);
  }
}
```

## Testing

### Local Development

```javascript
// Use testnet for development
const recurpay = new RecurPaySDK({
  network: 'base-sepolia',
  privateKey: process.env.TEST_PRIVATE_KEY
});

// Mock payment processing
const mockPayment = await recurpay.mockProcessPayment(subscriptionId);
```

### Integration Tests

```javascript
describe('RecurPay Integration', () => {
  it('should create and manage subscription', async () => {
    const plan = await recurpay.createPlan(testPlanConfig);
    const subscription = await recurpay.subscribe({
      planId: plan.id,
      subscriber: testAddress
    });
    
    expect(subscription.status).toBe('active');
  });
});
```

## Best Practices

### Security
- Never expose private keys in client-side code
- Validate all user inputs
- Implement proper access controls
- Use HTTPS for all webhook endpoints

### Performance
- Batch operations when possible
- Cache frequently accessed data
- Use appropriate gas limits
- Monitor transaction costs

### User Experience
- Provide clear payment status updates
- Implement graceful error handling
- Offer multiple payment options
- Send proactive notifications

## Support

### Documentation
- [API Reference](./API.md)
- [Smart Contract Docs](./CONTRACTS.md)
- [Troubleshooting](./TROUBLESHOOTING.md)

### Community
- Discord: [discord.gg/recurpay](https://discord.gg/recurpay)
- GitHub: [github.com/recurpay/protocol](https://github.com/recurpay/protocol)
- Twitter: [@RecurPayProtocol](https://twitter.com/RecurPayProtocol)
