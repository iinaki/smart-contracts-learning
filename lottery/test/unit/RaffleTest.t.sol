// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test,console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/Mocks/VRFCoordinatorV2Mock.sol";

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
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 1000;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (entranceFee, interval, vrfCoordinator, gasLane, subscriptionId, callbackGasLimit, link, deployerKey) = (helperConfig.activeNetworkConfig());
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

    // CHECK UPKEEP

    function test_check_upkeep_returns_false_if_it_has_no_balance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded, "Upkeep should not be needed");
    }

    function test_check_upkeep_returns_false_if_raffle_not_open() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded, "Upkeep should not be needed");
    }

    // PERFORM UPKEEP

    function test_perform_upkeep_can_only_run_if_check_upkeep_is_true() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function test_perform_upkeep_reverts_if_check_upkeep_is_false() public {
        uint256 balance = 0;
        uin256 numPlayers = 0;
        uint256 raffleState = 0;

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, balance, numPlayers, raffleState));
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_perform_upkeep_updates_raffle_state_and_emits_request_id() public raffleEnteredAndTimePassed {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0, "Request ID should be emitted");
        assert(raffleState == Raffle.RaffleState.CALCULATING, "Raffle state should be calculating");
    }

    // FULLFILL RANDOM WORDS

    modifier skipFork() {
        if (block.number != 31337) {
            return;
        }
        _;
    }

    function test_fulfill_random_words_can_only_be_called_after_performin_upkeep(uint256 randomRequestId) public raffleEnteredAndTimePassed skipFork {
        // FUZZ TESTING
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function test_fullfill_random_words_picks_a_winner_resets_and_sends_money() public raffleEnteredAndTimePassed skipFork {
        uint256 additionalEntrants = 5;
        for (uint256 i = 1; i < additionalEntrants + 1; i++) {
            address player = makeAddr(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamps = raffle.getLastTimeStamp();

        // pretend to be chainlink vrf to get rand number and pick winner
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN, "Raffle should be open");
        assert(raffle.getRecentWinner() != address(0), "Winner should be picked");
        assert(raffle.getLenPlayers() == 0, "Players should be reset");
        assert(previousTimeStamps < raffle.getLastTimeStamp(), "Timestamp should be updated");
        assert(raffle.getRecentWinner().balance == STARTING_BALANCE + prize - entranceFee, "Winner should receive prize");
    }
}