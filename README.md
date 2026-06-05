# PrimeVault

A staking vault protocol that allows users to deposit PRIME tokens and earn ETH rewards over time.

## Contracts

- **PrimeToken**: ERC20 token used for staking
- **PrimeVault**: Staking vault that distributes ETH rewards to depositors

## Usage

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

1. Deploy `PrimeToken` with initial supply
2. Deploy `PrimeVault` with token address
3. Set reward rate via `setRewardRate()`
4. Fund vault with ETH via `depositRewards()`

## How It Works

1. Users deposit PRIME tokens into the vault
2. Owner deposits ETH rewards and sets a reward rate
3. Rewards accumulate based on deposit amount and time
4. Users can withdraw tokens and claim accumulated ETH rewards

