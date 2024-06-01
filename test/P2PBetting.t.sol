// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {P2PBetting} from "../src/P2PBetting.sol";
import "lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol";

contract P2PBettingTest is Test {
    P2PBetting bettingContract;
    address tipster = address(75);
    address challenger = address(1);
    address challenger2 = address(2);
    address challenger3 = address(3);

    uint256[] ganaLocal = [0, 0];
    uint256[] empate = [0, 2];
    uint256[] localMasDe3 = [1, 0, 0, 3];
    uint256[] visitanteMenosDe2 = [1, 1, 1, 2];
    uint256[] sumaDeAmbosIgualQue4 = [1, 2, 2, 4];
    uint256[] diferenciaMenosQue4 = [1, 3, 1, 1];
    uint256[] ambosMenosDe1 = [1, 4, 1, 1];

    function setUp() public {
        bettingContract = new P2PBetting(2000, address(this), 7);
        vm.deal(tipster, 100 ether);
        vm.deal(challenger, 10 ether);
        vm.deal(challenger2, 10 ether);
        vm.deal(challenger3, 10 ether);
        bettingContract.testingAddMatch(
            437,
            block.timestamp + 8 days,
            "OKC",
            "DAL",
            100,
            1
        );
        bettingContract.testingAddMatch(
            765,
            block.timestamp + 9 days,
            "BOS",
            "CLE",
            134,
            78
        );
        bettingContract.testingAddMatch(
            1086,
            block.timestamp + 10 days + 12 hours,
            "MAD",
            "BAR",
            2,
            2
        );
        bettingContract.testingAddMatch(
            35666,
            block.timestamp + 8 days + 30 minutes,
            "SEA",
            "PIT",
            14,
            20
        );
    }

    function testCreateBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        // Check if bet is created successfully
        P2PBetting.Bet memory bet = bettingContract.getBet(0);
        assertEq(bet.maxNumberOfChallengers, 1);
        assertEq(bet.odds, 1500);
        assertEq(bet.maxEntryFee, 1 ether);
        assertEq(bet.moneyInBet, 10 ether);
        assertEq(bet.matchId, 437);
        assertEq(bet.betData[0], 0);
        assertEq(bet.betData[1], 0);
        assertEq(bettingContract.getNumberOfBets(), 1);
        assertEq(bettingContract.getProfile(tipster).betIdHistory[0], 0);
        assertEq(
            bettingContract.getProfile(tipster).balanceVariation,
            -10 ether
        );
    }

    function testCreateBetRevertsNotEnoughEth() public {
        vm.startPrank(tipster);
        vm.expectRevert(P2PBetting.P2PBetting__NotEnoughEthSent.selector);
        bettingContract.createBet{value: 0.4 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
    }

    function testCreateBetRevertsNumberOfChallengersCantBeZero() public {
        vm.startPrank(tipster);
        vm.expectRevert(
            P2PBetting.P2PBetting__NumberOfChallengersCantBeZero.selector
        );
        bettingContract.createBet{value: 10 ether}(
            437,
            0,
            1500,
            1 ether,
            ganaLocal
        );
    }

    function testCreateBetRevertsMaxPriceCantBeZero() public {
        vm.startPrank(tipster);
        vm.expectRevert(P2PBetting.P2PBetting__MaxPriceCantBeZero.selector);
        bettingContract.createBet{value: 10 ether}(437, 1, 1500, 0, ganaLocal);
    }

    function testCreateBetRevertsOddsMustBeHigherThanOne() public {
        vm.startPrank(tipster);
        vm.expectRevert(
            P2PBetting.P2PBetting__OddsMustBeHigherThanOne.selector
        );
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            900,
            1 ether,
            ganaLocal
        );
    }

    function testJoinBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        // Check if the user has successfully joined the bet
        P2PBetting.Profile memory profile = bettingContract.getProfile(
            challenger
        );
        assertEq(profile.betIdHistory.length, 1);
        assertEq(profile.balanceVariation, -int256(1 ether));
        P2PBetting.Bet memory bet = bettingContract.getBet(0);
        assertEq(bet.challengers.length, 1);
        assertEq(bet.moneyInBet, 11 ether);
        assertEq(bet.challengersMoneyBet[0], 1 ether);
    }

    function testJoinBetRevertsTooMuchEthSent() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.deal(challenger, 2 ether);
        vm.startPrank(challenger);
        vm.expectRevert(P2PBetting.P2PBetting__TooMuchEthSent.selector);
        bettingContract.joinBet{value: 2 ether}(0);
    }

    function testJoinBetRevertsBetIsFull() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__BetIsFullOrNonexistent.selector);
        bettingContract.joinBet{value: 1 ether}(0);
    }

    function testJoinBetRevertsBetIsNonexistent() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__BetIsFullOrNonexistent.selector);
        bettingContract.joinBet{value: 1 ether}(5);
    }

    function testJoinBetRevertsBetIsEnded() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, false);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__CantEnterBetNow.selector);
        bettingContract.joinBet{value: 1 ether}(0);
    }

    function testJoinBetRevertsBetIsLocked() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.warp(bettingContract.getBet(0).startMatchTimestamp + 5 hours);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__CantEnterBetNow.selector);
        bettingContract.joinBet{value: 1 ether}(0);
    }

    function testEndBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, true);
        // Check if the bet is ended successfully
        P2PBetting.Bet memory bet = bettingContract.getBet(0);
        assertTrue(bet.ended);
        assertTrue(bet.tipsterWon);
    }

    function testGetRewardsChallenger() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, false);
        console.log(address(bettingContract).balance);

        vm.prank(challenger);
        bettingContract.getRewards(0, 0);
        uint256 expectedFeeCollected = (1.5 ether * bettingContract.getFee()) /
            (100 * 1000);
        // Check if the rewards are claimed successfully
        P2PBetting.Profile memory profile = bettingContract.getProfile(
            challenger
        );
        console.log(expectedFeeCollected);
        assertEq(profile.balanceVariation, 1 ether * (1500 / 1000) - 1 ether);
        assertEq(
            address(challenger).balance,
            10.5 ether - expectedFeeCollected
        );
    }

    function testGetRewardsTipster() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, true);
        console.log(address(bettingContract).balance);
        vm.prank(tipster);
        bettingContract.getRewards(0, 0);
        // Check if the rewards are claimed successfully
        P2PBetting.Profile memory profile = bettingContract.getProfile(tipster);
        uint256 expectedFeeCollected = (1.5 ether * bettingContract.getFee()) /
            (100 * 1000);
        console.log(expectedFeeCollected);
        assertEq(profile.balanceVariation, 1 ether);
        assertEq(address(tipster).balance, 101 ether - expectedFeeCollected);
    }

    function testGetCollateralBack() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, false);
        bettingContract.getCollateralBack(0);
        assertEq(address(tipster).balance, 99.5 ether);
    }

    function testGetCollateralBackRevertsAlreadyRetrieved() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, false);
        bettingContract.getCollateralBack(0);
        vm.expectRevert(
            P2PBetting.P2PBetting__AlreadyRetrievedOrBetNonexistent.selector
        );
        bettingContract.getCollateralBack(0);
    }

    function testGetCollateralBackRevertsBetNonexistent() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, false);
        vm.expectRevert(
            P2PBetting.P2PBetting__AlreadyRetrievedOrBetNonexistent.selector
        );
        bettingContract.getCollateralBack(1);
    }

    function testGetCollateralBackRevertsTipsterWon() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, true);
        vm.expectRevert(
            P2PBetting.P2PBetting__OnlyCalledIfTipsterLost.selector
        );
        bettingContract.getCollateralBack(0);
    }

    function testGetCollateralBackRevertsBetNotEnded() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.expectRevert(
            P2PBetting.P2PBetting__OnlyCalledIfTipsterLost.selector
        );
        bettingContract.getCollateralBack(0);
    }

    function testCalculateFees() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(bettingContract.owner());
        bettingContract.endBetOwner(0, true);
        vm.prank(tipster);
        bettingContract.getRewards(0, 0);
        uint256 expectedFeeCollected = (1.5 ether * bettingContract.getFee()) /
            (100 * 1000);
        // Check if the fees are collected successfully
        assertEq(bettingContract.getFeesCollected(), expectedFeeCollected); // 2% fee collected
    }

    function testGetFee() public view {
        uint256 expectedFee = 2000; // Coloca el valor esperado aquí
        uint256 actualFee = bettingContract.getFee();
        assertEq(actualFee, expectedFee);
    }

    function testGetOracle() public {
        address expectedOracle = address(5); // Coloca la dirección esperada aquí
        vm.prank(bettingContract.owner());
        bettingContract.setUsdOracle(expectedOracle);
        address actualOracle = bettingContract.getOracle();
        assertEq(actualOracle, expectedOracle);
    }

    function testGetProfile() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(tipster);
        bettingContract.createBet{value: 5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(1);
        P2PBetting.Profile memory actualProfile = bettingContract.getProfile(
            challenger
        );
        assertEq(actualProfile.balanceVariation, -1e18);
        assertEq(actualProfile.betIdHistory[0], 1);
        // Asegúrate de verificar otros campos si existen en la estructura Profile
    }

    function testGetBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(tipster);
        bettingContract.createBet{value: 5 ether}(
            437,
            1,
            1500,
            2 ether,
            ganaLocal
        );

        P2PBetting.Bet memory actualBet = bettingContract.getBet(2);
        assertEq(actualBet.moneyInBet, 5 ether);
        assertEq(actualBet.maxNumberOfChallengers, 1);
        assertEq(actualBet.challengers.length, 0);
        assertEq(actualBet.odds, 1500);
        assertEq(actualBet.maxEntryFee, 2 ether);
        assertEq(actualBet.fee, 2000);
        assertEq(actualBet.ended, false);
        assertEq(actualBet.tipsterWon, false);
        // Asegúrate de verificar otros campos si existen en la estructura Bet
    }

    function testGetNumberOfChallenger() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(challenger2);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.prank(challenger3);
        bettingContract.joinBet{value: 1 ether}(0);

        // Asume que tienes una función addChallenger para agregar participantes a las apuestas para las pruebas
        vm.prank(challenger3);
        uint256 actualNumberOfChallenger = bettingContract
            .getNumberOfChallenger(0);
        assertEq(actualNumberOfChallenger, 2);
    }

    function testGetNumberOfBets() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(
            437,
            1,
            1500,
            1 ether,
            ganaLocal
        );
        uint256 actualNumberOfBets = bettingContract.getNumberOfBets();
        assertEq(actualNumberOfBets, 4);
    }

    function testCloseBetLocalWon() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            ganaLocal
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            ganaLocal
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            ganaLocal
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            ganaLocal
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, false);
        assertEq(bettingContract.getBet(1).tipsterWon, false);
        assertEq(bettingContract.getBet(2).tipsterWon, true);
        assertEq(bettingContract.getBet(3).tipsterWon, true);
    }

    function testCloseBetEmpate() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            empate
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            empate
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            empate
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            empate
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, true);
        assertEq(bettingContract.getBet(1).tipsterWon, true);
        assertEq(bettingContract.getBet(2).tipsterWon, false);
        assertEq(bettingContract.getBet(3).tipsterWon, true);
    }

    function testCloseBetLocalMasDe3Goles() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            localMasDe3
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            localMasDe3
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            localMasDe3
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            localMasDe3
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, false);
        assertEq(bettingContract.getBet(1).tipsterWon, false);
        assertEq(bettingContract.getBet(2).tipsterWon, true);
        assertEq(bettingContract.getBet(3).tipsterWon, false);
    }

    function testCloseBetSumaIgualA4() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            sumaDeAmbosIgualQue4
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            sumaDeAmbosIgualQue4
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            sumaDeAmbosIgualQue4
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            sumaDeAmbosIgualQue4
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, true);
        assertEq(bettingContract.getBet(1).tipsterWon, true);
        assertEq(bettingContract.getBet(2).tipsterWon, false);
        assertEq(bettingContract.getBet(3).tipsterWon, true);
    }

    function testCloseBetVisitanteMenosDe2() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            visitanteMenosDe2
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            visitanteMenosDe2
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            visitanteMenosDe2
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            visitanteMenosDe2
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, false);
        assertEq(bettingContract.getBet(1).tipsterWon, true);
        assertEq(bettingContract.getBet(2).tipsterWon, true);
        assertEq(bettingContract.getBet(3).tipsterWon, true);
    }

    function testCloseBetDiferenciaMenosDe4() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            diferenciaMenosQue4
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            diferenciaMenosQue4
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            diferenciaMenosQue4
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            diferenciaMenosQue4
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, true);
        assertEq(bettingContract.getBet(1).tipsterWon, true);
        assertEq(bettingContract.getBet(2).tipsterWon, false);
        assertEq(bettingContract.getBet(3).tipsterWon, true);
    }

    function testCloseBetAmbosMenosDe1() public {
        vm.startPrank(tipster);
        bettingContract.createBet{value: 10 ether}(
            437,
            3,
            1500,
            1 ether,
            ambosMenosDe1
        );
        bettingContract.createBet{value: 10 ether}(
            765,
            3,
            1500,
            1 ether,
            ambosMenosDe1
        );
        bettingContract.createBet{value: 10 ether}(
            1086,
            3,
            1500,
            1 ether,
            ambosMenosDe1
        );
        bettingContract.createBet{value: 10 ether}(
            35666,
            3,
            1500,
            1 ether,
            ambosMenosDe1
        );
        vm.stopPrank();
        vm.startPrank(bettingContract.owner());
        bettingContract.testEndMatch(437);
        bettingContract.testEndMatch(765);
        bettingContract.testEndMatch(1086);
        bettingContract.testEndMatch(35666);
        bettingContract.endBetsUsingMatchId(437);
        bettingContract.endBetsUsingMatchId(765);
        bettingContract.endBetsUsingMatchId(1086);
        bettingContract.endBetsUsingMatchId(35666);
        assertEq(bettingContract.getBet(0).tipsterWon, true);
        assertEq(bettingContract.getBet(1).tipsterWon, true);
        assertEq(bettingContract.getBet(2).tipsterWon, true);
        assertEq(bettingContract.getBet(3).tipsterWon, true);
    }

    function testGetTimestamp() public {
        console.log(BokkyPooBahsDateTimeLibrary.timestampFromDate(2024, 5, 22));
    }

    function testDecoder() public {
        bytes
            memory bytesData = hex"00000000000000000000000000000000000000000000000000000000000007D00000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000006E";

        //string memory jsonString = string(bytesData);
        //console.log(jsonString);
        uint256 gameId;
        uint256 homeTeamScore;
        uint256 awayTeamScore;
        (gameId, homeTeamScore, awayTeamScore) = abi.decode(
            bytesData,
            (uint256, uint256, uint256)
        );
        console.log(gameId);
        console.log(homeTeamScore);
        console.log(awayTeamScore);
    }
}
