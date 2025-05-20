# Treasury Smart Contract

Treasury is a Sui Move-based vault contract for secure management of multiple token assets. It supports various token types, whitelist access control, and flexible asset management functions.

## Features

- **Multi-token Support**: Create separate vaults for different token types
- **Access Control**: Admin and whitelist mechanisms ensure asset security
- **Deposit & Withdrawal**: Secure deposit and withdrawal functions
- **Cross-token Trading**: Token swaps via Cetus aggregator integration

## Contract Structure

- **TreasuryConfig**: Vault configuration containing admin address and whitelist table
- **Treasury\<T\>**: Generic vault that can store any token type
- **Permission Functions**: Whitelist and admin authority management
- **Asset Operations**: Functions for deposits, withdrawals, and swaps

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

After successful deployment, note the returned package ID and created object IDs.

## CLI Usage Guide

### 1. Create SUI Token Treasury

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function create_and_share_treasury \
  --type-args "0x2::sui::SUI" \
  --gas-budget 10000000
```

### 2. Create Other Token Treasury (e.g. CETUS)

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function create_and_share_treasury \
  --type-args "0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS" \
  --gas-budget 10000000
```

### 3. Add Address to Whitelist

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function add_to_whitelist \
  --args <TREASURY_CONFIG_ID> <ADDRESS_TO_WHITELIST> \
  --gas-budget 10000000
```

### 4. Remove Address from Whitelist

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function remove_from_whitelist \
  --args <TREASURY_CONFIG_ID> <ADDRESS_TO_REMOVE> \
  --gas-budget 10000000
```

### 5. Deposit Tokens

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function deposit \
  --type-args "0x2::sui::SUI" \
  --args <TREASURY_ID> <COIN_OBJECT_ID> \
  --gas-budget 10000000
```

### 6. Withdraw Tokens

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function withdraw \
  --type-args "0x2::sui::SUI" \
  --args <TREASURY_CONFIG_ID> <TREASURY_ID> <AMOUNT> \
  --gas-budget 10000000
```

### 7. Transfer Admin Rights

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module treasury \
  --function transfer_admin \
  --args <TREASURY_CONFIG_ID> <NEW_ADMIN_ADDRESS> \
  --gas-budget 10000000
```

### 8. Query Treasury Balance

```bash
sui client object <TREASURY_ID> --json | grep -A 5 balance
```

## TypeScript Script Usage

The project provides several TypeScript scripts for complex operations:

### Deposit Operation

```bash
npx ts-node src/scripts/deposit.ts
```

### Token Swap Operation

```bash
npx ts-node src/scripts/swap.ts
```

### Balance Query

```bash
npx ts-node src/scripts/check-balance.ts
```

### View Whitelist

```bash
npx ts-node src/scripts/check-whitelist.ts
```

## Important Notes

1. Each token type requires a separate treasury instance
2. Only admin and whitelisted addresses can withdraw tokens
3. Anyone can deposit tokens into the treasury
4. Private key information is sensitive and should be stored as environment variables
5. Set an appropriate gas budget before each operation

## Security Tips

- Never hardcode private keys in your code
- Test with small amounts before transferring large assets
- Regularly check whitelist status to ensure security
- Consider using multisig or timelock mechanisms for enhanced asset security