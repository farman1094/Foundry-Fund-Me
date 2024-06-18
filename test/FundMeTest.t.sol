// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {


    function setup() external{
        FundMe fundMe = new FundMe();
    }
    function testDemo() public {}
    }