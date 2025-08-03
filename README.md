# Decentralized Revenue Sharing Smart Contract

A transparent, decentralized smart contract for revenue sharing in collaborative projects built on the Stacks blockchain using Clarity.

## Overview

This smart contract enables transparent profit distribution for collaborative projects by allowing project owners to:
- Create revenue-sharing projects
- Add team members with specific share allocations
- Receive and distribute revenue automatically based on predefined shares
- Maintain full transparency of all transactions and distributions

## Features

- **Project Management**: Create and manage multiple revenue-sharing projects
- **Member Management**: Add, update, and remove project members with flexible share allocation
- **Automatic Revenue Distribution**: Fair distribution based on member shares
- **Transparent Tracking**: All revenue and withdrawals are tracked on-chain
- **Access Control**: Project owners have full control over their projects
- **Emergency Controls**: Projects can be paused/resumed as needed

## Contract Functions

### Read-Only Functions

- `get-project(project-id)`: Retrieve project details
- `get-project-member(project-id, member)`: Get member information for a project
- `get-project-balance(project-id)`: Check current project balance
- `calculate-member-share(project-id, member)`: Calculate total share amount for a member
- `calculate-withdrawable-amount(project-id, member)`: Calculate available withdrawal amount
- `get-total-projects()`: Get total number of projects created

### Public Functions

- `create-project(name)`: Create a new revenue-sharing project
- `add-project-member(project-id, member, shares)`: Add a member to a project with specified shares
- `update-member-shares(project-id, member, new-shares)`: Update member's share allocation
- `deposit-revenue(project-id, amount)`: Deposit revenue to be distributed
- `withdraw-share(project-id)`: Withdraw available share amount
- `toggle-project-status(project-id)`: Pause/resume a project
- `remove-project-member(project-id, member)`: Remove a member from the project

## Usage Examples

### Creating a Project
```clarity
(contract-call? .revenue-sharing create-project "My Awesome Project")
```

### Adding Team Members
```clarity
;; Add developer with 40% share (4000 basis points)
(contract-call? .revenue-sharing add-project-member u1 'ST1DEVELOPER 4000)

;; Add designer with 30% share (3000 basis points)
(contract-call? .revenue-sharing add-project-member u1 'ST1DESIGNER 3000)

;; Add marketer with 30% share (3000 basis points)
(contract-call? .revenue-sharing add-project-member u1 'ST1MARKETER 3000)
```

### Depositing Revenue
```clarity
;; Deposit 1000 STX as project revenue
(contract-call? .revenue-sharing deposit-revenue u1 1000000000)
```

### Withdrawing Shares
```clarity
;; Each member can withdraw their proportional share
(contract-call? .revenue-sharing withdraw-share u1)
```

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Caller not authorized for this action
- `ERR-INVALID-AMOUNT (u101)`: Invalid amount specified
- `ERR-PROJECT-NOT-FOUND (u102)`: Project does not exist
- `ERR-ALREADY-MEMBER (u103)`: Member already exists in project
- `ERR-NOT-MEMBER (u104)`: Address is not a project member
- `ERR-INSUFFICIENT-BALANCE (u105)`: Insufficient contract balance
- `ERR-INVALID-PERCENTAGE (u106)`: Invalid percentage value
- `ERR-PROJECT-LOCKED (u107)`: Project is currently inactive
- `ERR-NO-FUNDS-TO-DISTRIBUTE (u108)`: No funds available for distribution

## Security Features

- **Access Control**: Only project owners can manage their projects
- **Validation**: All inputs are validated before execution
- **Safe Math**: Prevents overflow and underflow issues
- **Transparent State**: All project data is publicly accessible
- **Immutable Records**: Transaction history cannot be altered

## Gas Optimization

The contract is optimized for gas efficiency through:
- Efficient data structure design
- Minimal storage operations
- Batch operations where possible
- Optimized calculation functions

## Testing

Before deploying to mainnet, thoroughly test all functions:

1. Create test projects
2. Add/remove members
3. Deposit and withdraw funds
4. Test edge cases and error conditions
5. Verify calculations are accurate

## Deployment

1. Deploy the contract to Stacks testnet first
2. Perform comprehensive testing
3. Conduct security audit if needed
4. Deploy to Stacks mainnet

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For questions or issues, please open an issue in the repository or contact the development team.

## Disclaimer

This smart contract is provided as-is. Users should thoroughly test and audit the code before using it in production environments. The developers are not responsible for any losses incurred through the use of this contract.