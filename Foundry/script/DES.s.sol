// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/DES.sol";

contract CounterScript is Script {
    DecentralizedEmploymentSystem public DES;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        DES = new DES();

        vm.stopBroadcast();
    }
}
