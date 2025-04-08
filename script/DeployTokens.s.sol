// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";
import {MockToken} from "../test/mocks/MockToken.sol";

contract DeployTokens is DeployHelpers {
    uint256 constant INITIAL_SUPPLY = 1_000_000_000; // 1 billion base units

    MockV3Aggregator public usdcUsdPriceFeed;
    MockV3Aggregator public wethUsdPriceFeed;

    function run() public {
        uint256 deployerKey = getDeployerKey();
        console.log("Deployer Key:", deployerKey);

        vm.startBroadcast(deployerKey);

        MockToken usdc = new MockToken("Mock USDC", "USDC", 6);
        MockToken weth = new MockToken("Mock WETH", "WETH", 18);

        usdc.mint(msg.sender, INITIAL_SUPPLY * 1e6);
        weth.mint(msg.sender, INITIAL_SUPPLY * 1e18);

        usdcUsdPriceFeed = new MockV3Aggregator(8, 1e8); // 1 USDE = 1 USD
        wethUsdPriceFeed = new MockV3Aggregator(8, 1800e8); // 1 WETH = 3000 USD

        console.log("USDC_ADDRESS=%s", address(usdc));
        console.log("WETH_ADDRESS=%s", address(weth));
        console.log("USDC_USD_DATAFEED_ADDRESS=%s", address(usdcUsdPriceFeed));
        console.log("WETH_USD_DATAFEED_ADDRESS=%s", address(wethUsdPriceFeed));

        vm.stopBroadcast();
    }
}
