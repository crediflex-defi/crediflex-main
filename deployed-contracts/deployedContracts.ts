/**
 * This file is autogenerated by Scaffold-ETH.
 * You should not edit it manually or your changes might be overwritten.
 */

interface ContractDetails {
  address: string;
  abi: any[];
  inheritedFunctions?: any;
}

interface DeployedContracts {
  [chainId: string]: {
    [contractName: string]: ContractDetails;
  };
}

export const deployedContracts: DeployedContracts = {
  31337: {},
  421614: {},
  11155111: {
    MockUsde: {
      address: "0x07d6f30c5c192dcb344fe0b56974d8b400fdd6de",
      abi: [
        {
          type: "constructor",
          inputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "allowance",
          inputs: [
            {
              name: "owner",
              type: "address",
              internalType: "address",
            },
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "approve",
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "balanceOf",
          inputs: [
            {
              name: "account",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "decimals",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint8",
              internalType: "uint8",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "mint",
          inputs: [
            {
              name: "to",
              type: "address",
              internalType: "address",
            },
            {
              name: "amount",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "name",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "symbol",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "totalSupply",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "transfer",
          inputs: [
            {
              name: "to",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "transferFrom",
          inputs: [
            {
              name: "from",
              type: "address",
              internalType: "address",
            },
            {
              name: "to",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "event",
          name: "Approval",
          inputs: [
            {
              name: "owner",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "spender",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "Transfer",
          inputs: [
            {
              name: "from",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "to",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "error",
          name: "ERC20InsufficientAllowance",
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
            {
              name: "allowance",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "needed",
              type: "uint256",
              internalType: "uint256",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InsufficientBalance",
          inputs: [
            {
              name: "sender",
              type: "address",
              internalType: "address",
            },
            {
              name: "balance",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "needed",
              type: "uint256",
              internalType: "uint256",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidApprover",
          inputs: [
            {
              name: "approver",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidReceiver",
          inputs: [
            {
              name: "receiver",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidSender",
          inputs: [
            {
              name: "sender",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidSpender",
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
          ],
        },
      ],
      inheritedFunctions: {
        allowance: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        approve: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        balanceOf: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        decimals: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        name: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        symbol: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        totalSupply:
          "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        transfer: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        transferFrom:
          "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
      },
    },
    MockWETH: {
      address: "0x20aa273781e20adec9abb6d8909c7063e8a17c55",
      abi: [
        {
          type: "constructor",
          inputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "allowance",
          inputs: [
            {
              name: "owner",
              type: "address",
              internalType: "address",
            },
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "approve",
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "balanceOf",
          inputs: [
            {
              name: "account",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "decimals",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint8",
              internalType: "uint8",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "mint",
          inputs: [
            {
              name: "to",
              type: "address",
              internalType: "address",
            },
            {
              name: "amount",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "name",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "symbol",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "totalSupply",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "transfer",
          inputs: [
            {
              name: "to",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "transferFrom",
          inputs: [
            {
              name: "from",
              type: "address",
              internalType: "address",
            },
            {
              name: "to",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "event",
          name: "Approval",
          inputs: [
            {
              name: "owner",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "spender",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "Transfer",
          inputs: [
            {
              name: "from",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "to",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "error",
          name: "ERC20InsufficientAllowance",
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
            {
              name: "allowance",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "needed",
              type: "uint256",
              internalType: "uint256",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InsufficientBalance",
          inputs: [
            {
              name: "sender",
              type: "address",
              internalType: "address",
            },
            {
              name: "balance",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "needed",
              type: "uint256",
              internalType: "uint256",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidApprover",
          inputs: [
            {
              name: "approver",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidReceiver",
          inputs: [
            {
              name: "receiver",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidSender",
          inputs: [
            {
              name: "sender",
              type: "address",
              internalType: "address",
            },
          ],
        },
        {
          type: "error",
          name: "ERC20InvalidSpender",
          inputs: [
            {
              name: "spender",
              type: "address",
              internalType: "address",
            },
          ],
        },
      ],
      inheritedFunctions: {
        allowance: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        approve: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        balanceOf: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        decimals: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        name: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        symbol: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        totalSupply:
          "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        transfer: "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
        transferFrom:
          "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol",
      },
    },
    MockV3Aggregator: {
      address: "0x2c015104c0a0bc6720abb970b1ba896bc157ba09",
      abi: [
        {
          type: "constructor",
          inputs: [
            {
              name: "_decimals",
              type: "uint8",
              internalType: "uint8",
            },
            {
              name: "_initialAnswer",
              type: "int256",
              internalType: "int256",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "decimals",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint8",
              internalType: "uint8",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "description",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "string",
              internalType: "string",
            },
          ],
          stateMutability: "pure",
        },
        {
          type: "function",
          name: "getAnswer",
          inputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "int256",
              internalType: "int256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getRoundData",
          inputs: [
            {
              name: "_roundId",
              type: "uint80",
              internalType: "uint80",
            },
          ],
          outputs: [
            {
              name: "roundId",
              type: "uint80",
              internalType: "uint80",
            },
            {
              name: "answer",
              type: "int256",
              internalType: "int256",
            },
            {
              name: "startedAt",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "updatedAt",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "answeredInRound",
              type: "uint80",
              internalType: "uint80",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "getTimestamp",
          inputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "latestAnswer",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "int256",
              internalType: "int256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "latestRound",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "latestRoundData",
          inputs: [],
          outputs: [
            {
              name: "roundId",
              type: "uint80",
              internalType: "uint80",
            },
            {
              name: "answer",
              type: "int256",
              internalType: "int256",
            },
            {
              name: "startedAt",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "updatedAt",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "answeredInRound",
              type: "uint80",
              internalType: "uint80",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "latestTimestamp",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "updateAnswer",
          inputs: [
            {
              name: "_answer",
              type: "int256",
              internalType: "int256",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "updateRoundData",
          inputs: [
            {
              name: "_roundId",
              type: "uint80",
              internalType: "uint80",
            },
            {
              name: "_answer",
              type: "int256",
              internalType: "int256",
            },
            {
              name: "_timestamp",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "_startedAt",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "version",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "uint256",
              internalType: "uint256",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "event",
          name: "AnswerUpdated",
          inputs: [
            {
              name: "current",
              type: "int256",
              indexed: true,
              internalType: "int256",
            },
            {
              name: "roundId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "updatedAt",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "NewRound",
          inputs: [
            {
              name: "roundId",
              type: "uint256",
              indexed: true,
              internalType: "uint256",
            },
            {
              name: "startedBy",
              type: "address",
              indexed: true,
              internalType: "address",
            },
            {
              name: "startedAt",
              type: "uint256",
              indexed: false,
              internalType: "uint256",
            },
          ],
          anonymous: false,
        },
      ],
      inheritedFunctions: {
        decimals:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        description:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        getAnswer:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        getRoundData:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        getTimestamp:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        latestAnswer:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        latestRound:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        latestRoundData:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        latestTimestamp:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
        version:
          "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol",
      },
    },
  },
} as const;
