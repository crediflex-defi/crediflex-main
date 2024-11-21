// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address usdeUsdDataFeed;
        address wethUsdDataFeed;
        address usde;
        address weth;
        uint256 deployerKey;
    }

    // Price Feed IDs provided by pyth
    // bytes32 _wethUsdDataFeed = bytes32(uint256(uint160(0x694AA1769357215DE4FAC081bf1f309aDC325306)));
    // bytes32 _usdeUsdDataFeed = bytes32(uint256(uint160(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43)));

    // usdeUsdDataFeed = AggregatorV2V3Interface(0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961);
    // wethUsdDataFeed = AggregatorV2V3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    uint8 public DECIMALS = 8;
    int64 public constant ETH_USD_PRICE = 3000e8;
    int64 public constant USDE_USD_PRICE = 110e6;
    uint256 public constant SUPPLY = 1000e18;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getEthMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            usdeUsdDataFeed: 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961,
            wethUsdDataFeed: 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961,
            usde: 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // check if there is an existing config
        if (activeNetworkConfig.wethUsdDataFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();

        MockV3Aggregator wethAggregator = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();
        wethMock.mint(msg.sender, SUPPLY);

        MockV3Aggregator usdeAggregator = new MockV3Aggregator(DECIMALS, USDE_USD_PRICE);
        ERC20Mock usdeMock = new ERC20Mock();
        usdeMock.mint(msg.sender, SUPPLY);

        vm.stopBroadcast();

        return NetworkConfig({
            usdeUsdDataFeed: address(usdeAggregator), // Use address of usdeAggregator
            wethUsdDataFeed: address(wethAggregator), // Use address of wethAggregator
            weth: address(wethMock),
            usde: address(usdeMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
