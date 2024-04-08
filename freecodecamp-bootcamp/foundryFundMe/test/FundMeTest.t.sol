// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
 
contract FoundMeTest {
    FundMe fundMe;

    function setUp() external {
        // deploy the contract
        fundMe = new FundMe();
    }

    function testMinimumDollarIsFive() public view {
        // check the minimum dollar is 5
        assert(fundMe.MINIMUM_USD() == 5e18);
    }

    function testOwnerIsDeployer() public view {
        // check the owner is the deployer
        assert(fundMe.i_owner() == address(this));
    }

    // with --rpc-url SEPOLIA_RPC_URL
    function testPriceFeedVersionIsAccurate() public view {
        // check the price feed version is accurate
        assert(fundMe.getVersion() == 4);
    }
}