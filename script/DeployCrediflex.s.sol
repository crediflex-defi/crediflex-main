// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Crediflex} from "../src/Crediflex.sol";
import {DeployHelpers} from "./DeployHelpers.s.sol";

contract DeployCrediflex is DeployHelpers {
    Crediflex public crediflex;

    function run(
        address usdeUsdDataFeed,
        address wethUsdDataFeed,
        address usde,
        address weth,
        address serviceManager
    ) public {
        uint256 deployerKey = getDeployerKey();
        console.log("Deployer Key:", deployerKey);
        vm.startBroadcast(deployerKey);

        crediflex = new Crediflex(serviceManager, usdeUsdDataFeed, wethUsdDataFeed, usde, weth);
        console.log("Crediflex deployed at:", address(crediflex));

        vm.stopBroadcast();

        exportDeployments();
    }
}
