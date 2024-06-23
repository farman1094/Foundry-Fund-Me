// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant sendValue = 10e18; //100000000000000000
    uint256 constant startingBal = 100e18; //10000000000000000000
    uint256 constant gasPrice = 1; //10000000000000000000

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, startingBal);
    }

    function testMinUsd() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // function to test Fund
    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); //The next line should revert
        // assert this line fail revert
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER); //The Next Tx will be sent by user
        fundMe.fund{value: sendValue}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        // vm.prank(USER); //The Next Tx will be sent by user
        // // fund.Me
        // fundMe.fund{value: sendValue}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, sendValue);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        // vm.prank(USER); //The Next Tx will be sent by user
        // fundMe.fund{value: sendValue}();
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); //The Next Tx will be sent by user
        vm.expectRevert(); //The next line should revert
        fundMe.withdraw();
        // assert this line fail revert
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        //To convert number into address we must use 160 instead of 256 as 160 is possible equal to address
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank(USER); //The Next Tx will be sent by user
            hoax(address(i), sendValue);
            fundMe.fund{value: sendValue}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(gasPrice);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    // function testWithdrawFromMultipleFunders() public funded {
    //     // Arrange
    //     vm.prank(USER); //The Next Tx will be sent by user
    //     uint256 starting1stOwnerBalance = fundMe.getOwner().balance;
    //     vm.prank(msg.sender); //The Next Tx will be sent by user
    //     fundMe.fund{value: sendValue}();
    //     uint256 starting2ndOwnerBalance = fundMe.getOwner().balance;
    //     uint256 startingFundMeBalance = address(fundMe).balance;

    //     // Act
    //     vm.prank(USER);
    //     fundMe.withdraw();
    //     vm.prank(msg.sender);
    //     fundMe.withdraw();

    //     //Assert
    //     uint256 ending1stOwnerBalance = fundMe.getOwner().balance;

    // //  AggregatorV3Interface priceFeed = AggregatorV3Interface();
    // }
}
