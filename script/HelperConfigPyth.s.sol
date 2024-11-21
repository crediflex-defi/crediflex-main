// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {IPyth, PythStructs} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {MockPyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address pyth;
        bytes32 wethUsdPriceFeedId;
        bytes32 usdeUsdPriceFeedId;
        address weth;
        address usde;
        uint256 deployerKey;
    }

    // Price Feed IDs provided by pyth
    bytes32 _wethUsdPriceFeedId = bytes32(uint256(uint160(0x694AA1769357215DE4FAC081bf1f309aDC325306)));
    bytes32 _usdeUsdPriceFeedId = bytes32(uint256(uint160(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43)));

    uint8 public DECIMALS = 8;
    int64 public constant ETH_USD_PRICE = 3000e8;
    int64 public constant USDE_USD_PRICE = 110e6;
    uint256 public constant SUPPLY = 1000e18;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 52085143) {
            activeNetworkConfig = getEthenaTesnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    // Reff Sponsored page
    // ETH/USD	ff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace
    // USDE/USD	3af6a3098c56f58ff47cc46dee4a5b1910e5c157f7f0b665952445867470d61f x
    // USDE/USD	6ec879b1e9963de5ee97e9c8710b742d6228252a5e2ca12d4ae81d7fe5ee8c5d

    function getEthenaTesnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            pyth: 0x2880aB155794e7179c9eE2e38200202908C17B43,
            wethUsdPriceFeedId: _wethUsdPriceFeedId,
            usdeUsdPriceFeedId: _usdeUsdPriceFeedId,
            weth: address(0),
            usde: 0x426E7d03f9803Dd11cb8616C65b99a3c0AfeA6dE,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
        // return NetworkConfig({
        //     pyth: 0x2880aB155794e7179c9eE2e38200202908C17B43,
        //     wethUsdPriceFeedId: _wethUsdPriceFeedId,
        //     usdeUsdPriceFeedId: _usdeUsdPriceFeedId,
        //     weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
        //     usde: 0x426E7d03f9803Dd11cb8616C65b99a3c0AfeA6dE,
        //     deployerKey: vm.envUint("PRIVATE_KEY")
        // });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // check if there is an existing config
        if (activeNetworkConfig.pyth != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();

        MockPyth _pyth = new MockPyth(60, 0);
        bytes memory priceFeedDataWeth = _pyth.createPriceFeedUpdateData(
            _wethUsdPriceFeedId, // WETH/USD price feed ID
            ETH_USD_PRICE, // Price
            3000000000, // Confidence interval
            -8, // Exponent
            ETH_USD_PRICE, // Exponential moving average price
            3000000000, // EMA confidence interval
            0, // Publish time
            0 // Previous publish time
        );

        bytes memory priceFeedDataUsde = _pyth.createPriceFeedUpdateData(
            _usdeUsdPriceFeedId, // USDE/USD price feed ID
            USDE_USD_PRICE, // Price
            1000000, // Confidence interval
            -8, // Exponent
            USDE_USD_PRICE, // Exponential moving average price
            1000000, // EMA confidence interval
            0, // Publish time
            0 // Previous publish time
        );

        bytes[] memory priceFeedDataArray = new bytes[](2);
        priceFeedDataArray[0] = priceFeedDataWeth;
        priceFeedDataArray[1] = priceFeedDataUsde;

        _pyth.updatePriceFeeds{value: 0}(priceFeedDataArray);

        ERC20Mock wethMock = new ERC20Mock();
        wethMock.mint(msg.sender, SUPPLY);

        ERC20Mock usdeMock = new ERC20Mock();
        usdeMock.mint(msg.sender, SUPPLY);

        vm.stopBroadcast();

        return NetworkConfig({
            pyth: address(_pyth),
            wethUsdPriceFeedId: _wethUsdPriceFeedId,
            usdeUsdPriceFeedId: _usdeUsdPriceFeedId,
            weth: address(wethMock),
            usde: address(usdeMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
