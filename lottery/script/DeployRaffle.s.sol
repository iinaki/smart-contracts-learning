// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint64 subscriptionId, 
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey) = (helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);  
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit, link, deployerKey);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle),vrfCoordinator,subscriptionId);

        return raffle, helperConfig;
    }
}