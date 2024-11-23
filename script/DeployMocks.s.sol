// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockUsde} from "../src/mocks/MockUsde.sol";
import {MockWETH} from "../src/mocks/MockWeth.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";
import {MockV3Aggregator} from "@chainlink/contracts/v0.8/tests/MockV3Aggregator.sol";

contract DeployMocks is DeployHelpers {
    MockUsde public mockUsde;
    MockWETH public mockWeth;
    MockV3Aggregator public usdeUsdPriceFeed;
    MockV3Aggregator public wethUsdPriceFeed;

    function run() public {
        uint256 deployerKey = getDeployerKey();
        console.log("Deployer Key:", deployerKey);
        vm.startBroadcast(deployerKey);

        mockUsde = new MockUsde();
        console.log("MockUsde deployed at:", address(mockUsde));

        mockWeth = new MockWETH();
        console.log("MockWETH deployed at:", address(mockWeth));

        usdeUsdPriceFeed = new MockV3Aggregator(8, 101e6); // 1 USDE = 1 USD
        console.log("USDE/USD Price Feed deployed at:", address(usdeUsdPriceFeed));

        wethUsdPriceFeed = new MockV3Aggregator(8, 3500e8); // 1 WETH = 3000 USD
        console.log("WETH/USD Price Feed deployed at:", address(wethUsdPriceFeed));

        vm.stopBroadcast();

        exportDeployments();
    }
}
