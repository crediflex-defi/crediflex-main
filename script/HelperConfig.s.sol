// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";
import {MockCrediflexServiceManager} from "test/mocks/MockCrediflexServiceManager.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";

contract HelperConfig is DeployHelpers {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address usdeUsdDataFeed;
        address wethUsdDataFeed;
        address usde;
        address weth;
        address serviceManager;
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

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetConfig();
        } else if (block.chainid == 421_614) {
            activeNetworkConfig = getArbitrumSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    //   MockUsde deployed at: 0x6AcaCCDacE944619678054Fe0eA03502ed557651
    //   MockWETH deployed at: 0x80207B9bacc73dadAc1C8A03C6a7128350DF5c9E
    //   USDE/USD Price Feed deployed at: 0x27D0Dd86F00b59aD528f1D9B699847A588fbA2C7
    //   WETH/USD Price Feed deployed at: 0x122e4C08f927AD85534Fc19FD5f3BC607b00C731
    function getArbitrumSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            usdeUsdDataFeed: 0x27D0Dd86F00b59aD528f1D9B699847A588fbA2C7,
            wethUsdDataFeed: 0x122e4C08f927AD85534Fc19FD5f3BC607b00C731,
            usde: 0x6AcaCCDacE944619678054Fe0eA03502ed557651,
            weth: 0x80207B9bacc73dadAc1C8A03C6a7128350DF5c9E,
            serviceManager: 0xc4327AD867E6e9a938e03815Ccdd4198ccE1023c
        });
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            usdeUsdDataFeed: 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961,
            wethUsdDataFeed: 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961,
            usde: 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3,
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            serviceManager: address(0) // need deployed first
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // check if there is an existing config
        if (activeNetworkConfig.wethUsdDataFeed != address(0)) {
            return activeNetworkConfig;
        }

        // vm.startBroadcast(getDeployerKey());

        MockV3Aggregator wethAggregator = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();
        wethMock.mint(msg.sender, SUPPLY);

        MockV3Aggregator usdeAggregator = new MockV3Aggregator(DECIMALS, USDE_USD_PRICE);
        ERC20Mock usdeMock = new ERC20Mock();
        usdeMock.mint(msg.sender, SUPPLY);

        MockCrediflexServiceManager serviceManager = new MockCrediflexServiceManager();

        // vm.stopBroadcast();

        return NetworkConfig({
            usdeUsdDataFeed: address(usdeAggregator), // Use address of usdeAggregator
            wethUsdDataFeed: address(wethAggregator), // Use address of wethAggregator
            weth: address(wethMock),
            usde: address(usdeMock),
            serviceManager: address(serviceManager)
        });
    }
}
