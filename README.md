# TradingFlow Vault Contract

TradingFlow Vault is a Sui Move-based asset management contract providing secure storage and transaction capabilities for multiple token types. It features a unique early supporter recognition system through SupporterReward integration alongside dedicated interfaces for both users and trading bots.

## Features

- **Multi-token Support**: Store and manage any token type in a single BalanceManager
- **Tiered Access Control**: Different capabilities for admins, bots, users, and early supporters
- **SupporterReward Integration**: Special privileges for early project backers
- **Slippage Protection**: Minimum deposit safeguards for bot operations
- **Version Control**: Contract versioning for safe upgrades

## Contract Structure

- **BalanceManager**: Core component managing multi-token balances for each user
- **AccessList**: Controls which bot addresses can perform automated operations
- **Record**: Tracks owner-to-BalanceManager mappings
- **AdminCap**: Administrative capability for privileged operations
- **Version**: Manages contract versioning for future upgrades

## Build & Deployment

### Prerequisites

1. Install Sui CLI
```bash
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui
```

2. Install project dependencies
```bash
npm install
```

3. Create `.env` file with your private key and addresses
```
PRIVATE_KEY=your_private_key_here
```

### Building the Contract

```bash
sui move build
```

### Deploying the Contract

```bash
sui client publish --gas-budget 100000000
```

After successful deployment, note the returned package ID and created object IDs for Record, AccessList, and Version.

## CLI Usage Guide

### 1. Add Bot to Access Control List

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function acl_add \
  --args <ADMIN_CAP_ID> <ACCESS_LIST_ID> <BOT_ADDRESS> \
  --gas-budget 10000000
```

### 2. Remove Bot from Access Control List

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function acl_remove \
  --args <ADMIN_CAP_ID> <ACCESS_LIST_ID> <BOT_ADDRESS> \
  --gas-budget 10000000
```

### 3. Create Balance Manager (Requires SupporterReward)

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function create_balance_manager \
  --args <RECORD_ID> <SUPPORTER_REWARD_ID> <VERSION_ID> \
  --gas-budget 10000000
```

### 4. User Deposit (With SupporterReward)

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function user_deposit \
  --type-args "0x2::sui::SUI" \
  --args <BALANCE_MANAGER_ID> <COIN_OBJECT_ID> <SUPPORTER_REWARD_ID> <VERSION_ID> \
  --gas-budget 10000000
```

### 5. User Withdraw (With SupporterReward)

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function user_withdraw \
  --type-args "0x2::sui::SUI" \
  --args <BALANCE_MANAGER_ID> <AMOUNT> <SUPPORTER_REWARD_ID> <VERSION_ID> \
  --gas-budget 10000000
```

### 6. Bot Deposit (Requires Access List)

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function bot_deposit \
  --type-args "0x2::sui::SUI" \
  --args <ACCESS_LIST_ID> <BALANCE_MANAGER_ID> <COIN_OBJECT_ID> <MIN_AMOUNT> \
  --gas-budget 10000000
```

### 7. Bot Withdraw (Requires Access List)

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function bot_withdraw \
  --type-args "0x2::sui::SUI" \
  --args <ACCESS_LIST_ID> <BALANCE_MANAGER_ID> <AMOUNT> \
  --gas-budget 10000000
```

### 8. Query Balance

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module vault \
  --function query \
  --type-args "0x2::sui::SUI" \
  --args <BALANCE_MANAGER_ID> \
  --gas-budget 10000000
```

## SupporterReward Integration

This contract integrates with the SupporterReward system to provide early backers with special privileges:

1. **Requirements**:
   - SupporterReward must have a minimum amount of 1000 tokens
   - Project name must be "TradingFlow"

2. **Verification**:
   - All user operations require a valid SupporterReward
   - SupporterReward is checked before any balance operations

3. **Benefits**:
   - Create personal BalanceManager
   - Direct deposit and withdrawal access
   - Future premium features

## Understanding User vs Bot Operations

The contract offers two distinct interfaces:

### User Operations
- Require ownership of the BalanceManager
- Require valid SupporterReward verification
- Funds are automatically transferred to the user

### Bot Operations
- Require the calling address to be in AccessList
- Include slippage protection with minimum amount check
- Return Coin objects directly instead of transferring
- Designed for automated trading strategies

## Important Notes

1. Each user can create their own BalanceManager after proving early support
2. BalanceManager stores multiple token types using dynamic fields
3. Bot addresses must be added to the AccessList by an admin
4. The contract uses versioning to support future upgrades
5. When a user withdraws the exact available balance, the field is removed
