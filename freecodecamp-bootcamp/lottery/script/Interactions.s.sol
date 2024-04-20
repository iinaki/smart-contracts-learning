// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/Mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol"; //  forge install foundry-rs/forge-std@v1.7.0 --no-commit

contract CreateSubscription is Script {
    function run() external return (uint64) {
        return createSubUsingConfig();
    }

    function createSubUsingConfig public return (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , ,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public return (uint64) {
        console.log("Creating subscription on chainid: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinatorMock).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with id: ", subId);
        return subId;
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        fundSubUsingConfig();
    }

    function fundSubUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subscriptionId, , address link) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address link) public {
        console.log("Funding subscription on subID: ", subscriptionId);
        console.log("Funding subscription on chainid: ", block.chainid);
        console.log("using vrfcoordinator: ", vrfCoordinator);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script { // we are gonna need the lastly deployed raffle contract
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , uint64 subscriptionId, ,) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subscriptionId);
    }

    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("using vrfcoordinator: ", vrfCoordinator);
        console.log("using subscriptionId: ", subscriptionId);
        console.log("on chainid: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }
}