// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test,console} from "forge-std/Test.sol";

contract RaffleTest is Test {
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane; 
    uint64 subscriptionId; 
    uint32 callbackGasLimit;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 1000;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit, link) = (helperConfig.activeNetworkConfig());
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.s_raffleState() == Raffle.RaffleState.OPEN, "Raffle should be in open state");
    }

    // ENTER RAFFLE
    function testRaffle_reverts_when_you_dont_pay_enough() public view {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();

    }

    function testRaffle_records_player_when_they_enter() public view {
        vm.prank(PLAYER);
        
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER, "Player should be recorded");
    }

    function test_emits_event_on_entrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true,false,false,false,address(raffle));
        emit EnteredRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function test_cant_enter_when_raffle_is_calculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER); // si da invalid consumer en el perform upkeep -> consumer tiene que estar added en la UI de chainlink, agregar valid subscription a deploy raffle
        raffle.enterRaffle{value: entranceFee}();
    }

}