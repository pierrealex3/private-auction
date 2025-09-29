// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PrivateAuction} from "../src/PrivateAuction.sol";

contract PrivateAuctionTest is Test {
    PrivateAuction public auction;

    function setUp() public {
        auction = new PrivateAuction();
    }

}
