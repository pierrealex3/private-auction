// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {PrivateAuction} from "../src/PrivateAuction.sol";

contract PrivateAuctionScript is Script {
    PrivateAuction public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new PrivateAuction();

        vm.stopBroadcast();
    }
}
