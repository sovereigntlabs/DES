# Decentralized Employment System (DES) Smart Contract 🌐

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.0-blue)](https://soliditylang.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-latest-brightgreen)](https://www.openzeppelin.com/)

A blockchain-based employment management system implementing [EIP-7750](https://eips.ethereum.org/EIPS/eip-7750), [EIP-5192](https://eips.ethereum.org/EIPS/eip-5192) (Minimal Soulbound Tokens), and [EIP-721](https://eips.ethereum.org/EIPS/eip-721) standards for secure, transparent employment relationships.

---

## 📑 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technical Implementation](#technical-implementation)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Overview

The Decentralized Employment System (DES) is a smart contract solution that revolutionizes traditional employment relationships using blockchain technology. It implements soulbound NFTs for employee credentials, secure contract management, and transparent review systems.

### Key Components:

- **Employee Token Management**: Built on [EIP-721](https://eips.ethereum.org/EIPS/eip-721) and [EIP-5192](https://eips.ethereum.org/EIPS/eip-5192) standards for non-transferable NFTs.
- **Company Registration System**: Decentralized company profiles.
- **Smart Employment Contracts**: Agreements between companies and employees.
- **Automated Payments**: Secure salary deposits and releases.
- **Dispute Resolution Mechanism**: Built-in arbitration system.
- **Review System**: Transparent performance feedback mechanism.

---

## Features

- **Soulbound Employee Tokens**: Non-transferable NFTs representing employee credentials, compliant with [EIP-5192](https://eips.ethereum.org/EIPS/eip-5192).
- **Company Management**: Register and manage company profiles.
- **Smart Employment Contracts**: Create, execute, and manage employment agreements.
- **Automated Payments**: Secure salary deposits and releases.
- **Dispute Resolution**: Built-in arbitration system.
- **Review System**: Transparent performance feedback mechanism.

---

## Technical Implementation

### Standards Implemented

- [EIP-7750](https://eips.ethereum.org/EIPS/eip-7750): Enhanced Employment Token Standard.
- [EIP-5192](https://eips.ethereum.org/EIPS/eip-5192): Minimal Soulbound Token Implementation.
- [EIP-721](https://eips.ethereum.org/EIPS/eip-721): NFT Standard.

### Core Components

```solidity
struct Review {
        uint256 rating;
        string comments;
        address reviewer;
    }

    // Structs
    struct Company {
        string name;
        string industry;
        address owner;
        uint256[] employeeIds;
        bool isActive;
    }

    struct Contract {
        uint256 companyId;
        uint256 employeeTokenId;
        uint256 salary;
        uint256 duration;
        uint256 startTime;
        string responsibilities;
        string terminationConditions;
        ContractStatus status;
        uint256 balance;
        address employee;
        address arbitrator;
    }

    enum ContractStatus {
        Created,
        Active,
        Disputed,
        Terminated,
        Completed
    }
```

## Getting Started

### Prerequisites

- Node.js >= 14.0.0
- Hardhat or Foundry
- OpenZeppelin Contracts

### Installation

Refer to README.md in the respective Foundry/Hardhat folders

### Deployment

For Hardhat

```
npx hardhat run scripts/DES.js --network <your-network>

```

For Foundry

```
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Usage

### Company Registration

```
function registerCompany(string calldata name, string calldata industry)
    external
    returns (uint256 companyId)
```

### Employee Token Minting

```
function mintEmployeeToken(
    uint256 companyId,
    address employee,
    string calldata metadataURI
)
```

### Employment Contract Creation

```
function createContract(
    uint256 companyId,
    uint256 employeeTokenId,
    uint256 salary,
    uint256 duration,
    // ... additional parameters
)
```

## Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository.
2. Create your feature branch (git checkout -b feature/AmazingFeature).
3. Commit your changes (git commit -m 'Add some AmazingFeature').
4. Push to the branch (git push origin feature/AmazingFeature).
5. Open a Pull Request.

## Areas for Improvement

- Enhanced dispute resolution mechanisms.
- Additional employment contract templates.
- Integration with decentralized identity solutions.
- Improved salary tokenization features.
- Extended review system capabilities.
- Gas optimization.
- Cross-chain compatibility.
- Enhanced privacy features.

## Security

### Audit Status

- Initial audit pending.
- Bug bounty program coming soon.

### Known Considerations

- Locked token implementation.
- Payment system security.
- Arbitrator authority limits.

## License

This project is licensed under the MIT License

## Keywords

decentralized employment, blockchain HR, soulbound tokens, EIP-5192, EIP-721, smart contracts, employment NFT, Web3 jobs, blockchain employment, decentralized hiring.

## 📫 Contact

- Create an issue for bug reports.
- Submit a PR for contributions.
- Join our [Telegram](https://t.me/sovereigntlabs) community.

⭐ Star this repository if you find it helpful!
