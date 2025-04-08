// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Crediflex} from "../src/Crediflex.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";

contract DeployCrediflex is DeployHelpers {
    Crediflex public crediflex;

    function run(
        address usdcUsdDataFeed,
        address wethUsdDataFeed,
        address usdc,
        address weth,
        address serviceManager
    ) public {
        uint256 deployerKey = getDeployerKey();
        console.log("Deployer Key:", deployerKey);
        vm.startBroadcast(deployerKey);

        crediflex = new Crediflex(serviceManager, usdcUsdDataFeed, wethUsdDataFeed, usdc, weth);
        console.log("CREDIFLEX_ADDRESS=%s", address(crediflex));

        vm.stopBroadcast();

        // exportDeployments();
    }
}
