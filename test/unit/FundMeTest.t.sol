// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 10000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;

    // cheat code to always make USER the caller and send some value with it.
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // cheat code to create an user and give him some balance
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinumumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // console.log(address(this)); // address of this contract
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithouEnoughETH() public {
        vm.expectRevert(); // the next line should revert = fail
        // assert(This tx fails/reverts);
        fundMe.fund(); // send 0 founds
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundersToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public {
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

    function testWithdrawFromMultipleFunders() public {
        // Arrange
        uint160 numberOfFunders = 10;   
        uint160 startingFundersIndex = 1;
        for(uint160 i = numberOfFunders; i < startingFundersIndex; i++){
            // vm.prank() new address
            // vm.deal() new address
            // address()

            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assertion
       
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance
        );
        // assert(numberOfFunders * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
}
