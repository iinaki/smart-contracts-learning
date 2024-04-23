// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.sol";
 
contract FoundMeTest {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // deploy the contract
        DeployFundMe deplyFundMe = new DeployFundMe();
        fundMe = deplyFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        // check the minimum dollar is 5
        assert(fundMe.MINIMUM_USD() == 5e18);
    }

    function testOwnerIsDeployer() public view {
        // check the owner is the deployer
        assert(fundMe.getOwner() == msg.sender);
    }

    // with --rpc-url SEPOLIA_RPC_URL
    function testPriceFeedVersionIsAccurate() public view {
        // check the price feed version is accurate
        assert(fundMe.getVersion() == 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // check the fund fails without enough eth
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.s_addressToAmountFunded(USER);
        assert(amountFunded == SEND_VALUE); 
    }

    function testAddsFunderToFunders() public funded {
        address funder = fundMe.getFunders(0);
        assert(funder == USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundeMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundeMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assert(endingOwnerBalance == startingOwnerBalance + startingFundMeBalance);
        assert(endingFundMeBalance == 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        for(uint160 i = 1; i < 10; i++){
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundeMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assert(address(fundMe).balance == 0);
        address(startingFundMeBalance + startingOwnerBalance == address(fundMe).balance);
    }
}