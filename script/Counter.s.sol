// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Crediflex} from "../src/Crediflex.sol";

contract CrediflexScript is Script {
    Crediflex public crediflex;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // crediflex = new Crediflex(
        //     0x1234567890abcdef1234567890abcdef12345678, // Replace with actual Pyth address
        //     0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef, // Replace with actual WETH/USD price feed ID
        //     0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef, // Replace with actual USDE/USD price feed ID
        //     0x426E7d03f9803Dd11cb8616C65b99a3c0AfeA6dE, // USDE address
        //     0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2  // WETH address
        // );

        vm.stopBroadcast();
    }
}
