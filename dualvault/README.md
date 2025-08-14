# DualVault Treasury Management Protocol

**DualVault** is a sophisticated treasury management protocol built on the Stacks blockchain using Clarity smart contracts. It enables automated dual-asset portfolio management with built-in liquidity provision, yield optimization, and decentralized fund management capabilities.

## Overview

DualVault operates as a dual-asset treasury system that manages both primary assets (STX) and secondary assets (custom tokens) through an automated market-making mechanism. The protocol issues treasury units to investors proportional to their contributions and provides sophisticated trading and liquidity management features.

## Key Features

### 🏦 **Dual-Asset Treasury Management**
- Manages both primary (STX) and secondary (custom token) asset holdings
- Proportional unit issuance based on dual-asset contributions
- Automated portfolio rebalancing through trading mechanisms

### 💰 **Investor Unit System**
- Treasury units represent proportional ownership in the fund
- Automatic unit calculation based on current treasury ratios
- Fair redemption mechanism maintaining proportional ownership

### 📊 **Yield Optimization**
- Built-in 0.3% management fee structure
- Sophisticated yield calculations for investment returns
- Minimum yield protection for all trading operations

### 🔄 **Automated Market Making**
- Primary-to-secondary asset trading with yield calculations
- Secondary-to-primary asset trading capabilities
- Slippage protection through minimum yield requirements

### 📝 **Operations Logging**
- Comprehensive transaction logging for all treasury operations
- Timestamped operation records with detailed asset flows
- Full audit trail for regulatory compliance

## Smart Contract Architecture

### Core Components

**Treasury State Variables:**
- `treasury-primary-holdings`: Primary asset (STX) balance
- `treasury-secondary-holdings`: Secondary asset balance  
- `treasury-units-issued`: Total treasury units in circulation
- `treasury-operational`: Treasury operational status

**Investor Management:**
- `investor-units`: Maps investor addresses to their unit holdings
- Proportional ownership tracking and redemption rights

**Operations Tracking:**
- `operations-log`: Detailed transaction history
- `operation-ref-counter`: Unique operation reference system

### Key Functions

#### Treasury Establishment
```clarity
(establish-treasury asset-registry primary-seed secondary-seed)
```
Initializes the treasury with initial asset deposits and issues founding treasury units.

#### Fund Contribution
```clarity
(fund-treasury asset-registry primary-contribution secondary-contribution min-unit-issue)
```
Allows investors to contribute assets and receive proportional treasury units.

#### Position Liquidation
```clarity
(liquidate-treasury-position asset-registry unit-redemption min-primary min-secondary)
```
Enables investors to redeem treasury units for proportional asset withdrawals.

#### Asset Trading
```clarity
(execute-primary-to-secondary-trade asset-registry primary-investment min-secondary-yield)
(execute-secondary-to-primary-trade asset-registry secondary-investment min-primary-yield)
```
Automated trading functions with yield optimization and slippage protection.

## Mathematical Framework

### Yield Calculations
The protocol implements sophisticated yield calculations with a 0.3% management fee:

```
Net Investment = Investment Amount × 99.7%
Yield = (Net Investment × Target Holdings) / (Current Holdings × 1000 + Net Investment)
```

### Unit Allocation
Treasury units are calculated proportionally:

```
New Units = min(
  (Primary Contribution × Current Units) / Primary Holdings,
  (Secondary Contribution × Current Units) / Secondary Holdings
)
```

## Security Features

### Access Controls
- Treasury steward designation for administrative functions
- Investor-specific unit holdings and permissions
- Asset registry validation for all token operations

### Error Handling
Comprehensive error codes for various failure scenarios:
- `treasury-err-access-violation` (u800)
- `treasury-err-fund-shortage` (u801)
- `treasury-err-amount-invalid` (u802)
- `treasury-err-yield-insufficient` (u803)
- `treasury-err-asset-incompatible` (u804)
- `treasury-err-operation-failure` (u805)
- `treasury-err-fund-operational` (u806)
- `treasury-err-fund-dormant` (u807)

### Validation Mechanisms
- Minimum yield requirements for all trades
- Asset compatibility verification
- Operational status checks
- Sufficient balance validations

## Use Cases

### Institutional Treasury Management
- Corporate treasuries managing dual-asset portfolios
- Automated rebalancing and yield optimization
- Transparent operations with full audit trails

### Decentralized Fund Management
- Community-managed investment funds
- Proportional ownership and governance
- Automated market making for liquidity provision

### Yield Farming Protocols
- Sophisticated yield calculation mechanisms
- Multi-asset portfolio optimization
- Built-in fee structures for sustainable operations

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI tools
- Compatible secondary asset token contract

### Deployment Steps

1. **Deploy Secondary Asset Contract**
   Ensure your secondary asset implements the required `treasury-asset` trait.

2. **Deploy DualVault Contract**
   Deploy the treasury management contract to the Stacks blockchain.

3. **Initialize Treasury**
   Call `establish-treasury` with initial asset deposits to activate the system.

4. **Fund Operations**
   Investors can contribute assets through `fund-treasury` to participate in the treasury.

### Integration Example

```clarity
;; Example treasury establishment
(contract-call? .dualvault establish-treasury .my-token u1000000 u500000)

;; Example investment
(contract-call? .dualvault fund-treasury .my-token u100000 u50000 u45000)
```

## Roadmap

- [ ] Multi-asset support beyond dual-asset pairs
- [ ] Advanced governance mechanisms for treasury parameters
- [ ] Integration with external DeFi protocols
- [ ] Mobile-friendly treasury management interface
- [ ] Advanced analytics and reporting tools
