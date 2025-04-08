// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {MockToken} from "../test/mocks/MockToken.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";
import {MockCrediflexServiceManager} from "test/mocks/MockCrediflexServiceManager.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";

contract HelperConfig is DeployHelpers {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address usdcUsdDataFeed;
        address wethUsdDataFeed;
        address usdc;
        address weth;
        address serviceManager;
    }

    // Price Feed IDs provided by pyth
    // bytes32 _wethUsdDataFeed = bytes32(uint256(uint160(0x694AA1769357215DE4FAC081bf1f309aDC325306)));
    // bytes32 _usdcUsdDataFeed = bytes32(uint256(uint160(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43)));

    // usdcUsdDataFeed = AggregatorV2V3Interface(0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961);
    // wethUsdDataFeed = AggregatorV2V3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    uint8 public DECIMALS = 8;
    int64 public constant ETH_USD_PRICE = 1800e8;
    int64 public constant USDC_USD_PRICE = 1e8;
    uint256 public constant SUPPLY = 1000e18;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getEthMainnetConfig();
        } else if (block.chainid == 421_614) {
            activeNetworkConfig = getArbitrumSepoliaConfig();
        } else if (block.chainid == 656_476) {
            activeNetworkConfig = getEduChainTestnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    //   Mockusdc deployed at: 0x6AcaCCDacE944619678054Fe0eA03502ed557651
    //   MockWETH deployed at: 0x80207B9bacc73dadAc1C8A03C6a7128350DF5c9E
    //   usdc/USD Price Feed deployed at: 0x27D0Dd86F00b59aD528f1D9B699847A588fbA2C7
    //   WETH/USD Price Feed deployed at: 0x122e4C08f927AD85534Fc19FD5f3BC607b00C731
    function getArbitrumSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            usdcUsdDataFeed: vm.envAddress("ARBSEPOLIA_USDC_USD_DATAFEED_ADDRESS"),
            wethUsdDataFeed: vm.envAddress("ARBSEPOLIA_WETH_USD_DATAFEED_ADDRESS"),
            usdc: vm.envAddress("ARBSEPOLIA_USDC_ADDRESS"),
            weth: vm.envAddress("ARBSEPOLIA_WETH_ADDRESS"),
            serviceManager: vm.envAddress("ARBSEPOLIA_AVS_ADDRESS")
        });
    }

    function getEduChainTestnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            usdcUsdDataFeed: vm.envAddress("EDUCHAIN_USDC_USD_DATAFEED_ADDRESS"),
            wethUsdDataFeed: vm.envAddress("EDUCHAIN_WETH_USD_DATAFEED_ADDRESS"),
            usdc: vm.envAddress("EDUCHAIN_USDC_ADDRESS"),
            weth: vm.envAddress("EDUCHAIN_WETH_ADDRESS"),
            serviceManager: vm.envAddress("EDUCHAIN_AVS_ADDRESS")
        });
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            usdcUsdDataFeed: 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961,
            wethUsdDataFeed: 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961,
            usdc: 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3,
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
        MockToken weth = new MockToken("Mock WETH", "WETH", 18);
        weth.mint(msg.sender, SUPPLY);

        MockV3Aggregator usdcAggregator = new MockV3Aggregator(DECIMALS, USDC_USD_PRICE);
        MockToken usdc = new MockToken("Mock USDC", "USDC", 6);
        usdc.mint(msg.sender, SUPPLY);

        MockCrediflexServiceManager serviceManager = new MockCrediflexServiceManager();

        // vm.stopBroadcast();

        return NetworkConfig({
            usdcUsdDataFeed: address(usdcAggregator), // Use address of usdcAggregator
            wethUsdDataFeed: address(wethAggregator), // Use address of wethAggregator
            weth: address(weth),
            usdc: address(usdc),
            serviceManager: address(serviceManager)
        });
    }
}
