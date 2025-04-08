//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployCrediflex} from "./DeployCrediflex.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console} from "forge-std/Script.sol";
import "forge-std/Vm.sol";

contract Deploy {
    DeployCrediflex public deployCrediflex;

    function run() public {
        // deployMocks = new DeployMocks();
        // console.log("DeployMocks contract deployed at:", address(deployMocks));
        // deployMocks.run();

        HelperConfig config = new HelperConfig();
        (
            address usdeUsdDataFeed,
            address wethUsdDataFeed,
            address usde,
            address weth,
            address serviceManager
        ) = config.activeNetworkConfig();

        deployCrediflex = new DeployCrediflex();
        console.log("DeployCrediflex contract deployed at:", address(deployCrediflex));
        deployCrediflex.run(usdeUsdDataFeed, wethUsdDataFeed, usde, weth, serviceManager);
    }
}
