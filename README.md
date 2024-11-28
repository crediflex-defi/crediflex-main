# Crediflex Main Contracts

**Crediflex is a smart contract for managing supply, collateral, and borrowing of assets with dynamic Loan-to-Value (LTV) based on credit scores.**

## Features

- **Asset Supply**: Allows users to supply assets to the contract, increasing their supply shares.
- **Asset Withdrawal**: Enables users to withdraw their supply shares, converting them back to assets.
- **Collateral Supply**: Users can supply collateral to the contract, which is tracked separately.
- **Collateral Withdrawal**: Users can withdraw their supplied collateral, subject to health checks.
- **Asset Borrowing**: Facilitates borrowing of assets against collateral, with dynamic LTV based on credit scores.
- **Borrow Repayment**: Allows users to repay borrowed assets, reducing their borrow shares.
- **Interest Accrual**: Automatically accrues interest on borrowed assets over time.
- **Health Factor Monitoring**: Continuously checks the health of user positions to ensure they remain within safe limits.
- **Dynamic LTV Calculation**: Adjusts the Loan-to-Value ratio based on user credit scores, with thresholds and caps.
- **Data Feed Conversion**: Converts asset amounts using external data feeds for accurate pricing.
- **Collateral Management**: Allows users to deposit and withdraw collateral.
- **Borrowing**: Facilitates borrowing against collateral with interest accrual.

## Quick Start

The following instructions explain how to manually deploy the Crediflex main contracts from scratch using Foundry (forge) to a local Anvil chain, and start the associated services and tasks.

### Commands

| Command         | Description                                   |
| --------------- | --------------------------------------------- |
| `build`         | Builds the project.                           |
| `chain`         | Starts a local blockchain.                    |
| `deploy`        | Deploys the Crediflex contracts.              |
| `deploy:verify` | Deploys and verifies the Crediflex contracts. |
| `test`          | Runs tests on the smart contracts             |

To execute any of these commands, run:

```bash
npm run <command>
```

Replace `<command>` with any command from the list above (e.g., `npm run build`).
