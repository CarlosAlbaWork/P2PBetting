// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {P2PBetting} from "../src/P2PBetting.sol";

contract P2PBettingTest is Test {
    P2PBetting bettingContract;
    address tipster = address(75);
    address challenger = address(1);
    address challenger2 = address(2);
    address challenger3 = address(3);

    function setUp() public {
        bettingContract = new P2PBetting(2000, address(this));
        vm.deal(tipster, 10 ether);
        vm.deal(challenger, 1 ether);
        vm.deal(challenger2, 1 ether);
        vm.deal(challenger3, 1 ether);
    }

    function testCreateBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        // Check if bet is created successfully
        P2PBetting.Bet memory bet = bettingContract.getBet(0);
        assertEq(bet.maxNumberOfChallengers, 1);
        assertEq(bet.odds, 1500);
        assertEq(bet.maxEntryFee, 1 ether);
        assertEq(bet.moneyInBet, 10 ether);
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
        bettingContract.createBet{value: 0.4 ether}(1, 1500, 1 ether);
    }

    function testCreateBetRevertsNumberOfChallengersCantBeZero() public {
        vm.startPrank(tipster);
        vm.expectRevert(
            P2PBetting.P2PBetting__NumberOfChallengersCantBeZero.selector
        );
        bettingContract.createBet{value: 10 ether}(0, 1500, 1 ether);
    }

    function testCreateBetRevertsMaxPriceCantBeZero() public {
        vm.startPrank(tipster);
        vm.expectRevert(P2PBetting.P2PBetting__MaxPriceCantBeZero.selector);
        bettingContract.createBet{value: 10 ether}(1, 1500, 0 ether);
    }

    function testCreateBetRevertsOddsMustBeHigherThanOne() public {
        vm.startPrank(tipster);
        vm.expectRevert(
            P2PBetting.P2PBetting__OddsMustBeHigherThanOne.selector
        );
        bettingContract.createBet{value: 10 ether}(1, 900, 1 ether);
    }

    function testJoinBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
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
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.deal(challenger, 2 ether);
        vm.startPrank(challenger);
        vm.expectRevert(P2PBetting.P2PBetting__TooMuchEthSent.selector);
        bettingContract.joinBet{value: 2 ether}(0);
    }

    function testJoinBetRevertsBetIsFull() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__BetIsFullOrNonexistent.selector);
        bettingContract.joinBet{value: 1 ether}(0);
    }

    function testJoinBetRevertsBetIsNonexistent() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__BetIsFullOrNonexistent.selector);
        bettingContract.joinBet{value: 1 ether}(5);
    }

    function testJoinBetRevertsBetIsEnded() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        bettingContract.endBet(0, false);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__CantEnterBetNow.selector);
        bettingContract.joinBet{value: 1 ether}(0);
    }

    function testJoinBetRevertsBetIsLocked() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        bettingContract.lockBet(0);
        vm.startPrank(challenger2);
        vm.expectRevert(P2PBetting.P2PBetting__CantEnterBetNow.selector);
        bettingContract.joinBet{value: 1 ether}(0);
    }

    function testEndBet() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        bettingContract.endBet(0, true);
        // Check if the bet is ended successfully
        P2PBetting.Bet memory bet = bettingContract.getBet(0);
        assertTrue(bet.ended);
        assertTrue(bet.tipsterWon);
    }

    function testGetRewardsChallenger() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, false);
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
        assertEq(address(challenger).balance, 1.5 ether - expectedFeeCollected);
    }

    function testGetRewardsTipster() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, true);
        console.log(address(bettingContract).balance);
        vm.prank(tipster);
        bettingContract.getRewards(0, 0);
        // Check if the rewards are claimed successfully
        P2PBetting.Profile memory profile = bettingContract.getProfile(tipster);
        uint256 expectedFeeCollected = (1.5 ether * bettingContract.getFee()) /
            (100 * 1000);
        console.log(expectedFeeCollected);
        assertEq(profile.balanceVariation, 1 ether);
        assertEq(address(tipster).balance, 11 ether - expectedFeeCollected);
    }

    function testGetCollateralBack() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, false);
        bettingContract.getCollateralBack(0);
        assertEq(address(tipster).balance, 9.5 ether);
    }

    function testGetCollateralBackRevertsAlreadyRetrieved() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, false);
        bettingContract.getCollateralBack(0);
        vm.expectRevert(
            P2PBetting.P2PBetting__AlreadyRetrievedOrBetNonexistent.selector
        );
        bettingContract.getCollateralBack(0);
    }

    function testGetCollateralBackRevertsBetNonexistent() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, false);
        vm.expectRevert(
            P2PBetting.P2PBetting__AlreadyRetrievedOrBetNonexistent.selector
        );
        bettingContract.getCollateralBack(1);
    }

    function testGetCollateralBackRevertsTipsterWon() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, true);
        vm.expectRevert(
            P2PBetting.P2PBetting__OnlyCalledIfTipsterLost.selector
        );
        bettingContract.getCollateralBack(0);
    }

    function testGetCollateralBackRevertsBetNotEnded() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        vm.expectRevert(
            P2PBetting.P2PBetting__OnlyCalledIfTipsterLost.selector
        );
        bettingContract.getCollateralBack(0);
    }

    function testCalculateFees() public {
        vm.prank(tipster);
        bettingContract.createBet{value: 10 ether}(1, 1500, 1 ether);
        vm.prank(challenger);
        bettingContract.joinBet{value: 1 ether}(0);
        bettingContract.endBet(0, true);
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
        bettingContract.createBet{value: 5 ether}(1, 1500, 1 ether);
        vm.prank(tipster);
        bettingContract.createBet{value: 5 ether}(1, 1500, 1 ether);
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
        bettingContract.createBet{value: 2.5 ether}(1, 1500, 1 ether);
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(1, 1500, 1 ether);
        vm.prank(tipster);
        bettingContract.createBet{value: 5 ether}(1, 1500, 2 ether);

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
        bettingContract.createBet{value: 10 ether}(3, 1500, 1 ether);
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
        bettingContract.createBet{value: 2.5 ether}(1, 1500, 1 ether);
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(1, 1500, 1 ether);
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(1, 1500, 1 ether);
        vm.prank(tipster);
        bettingContract.createBet{value: 2.5 ether}(1, 1500, 1 ether);
        uint256 actualNumberOfBets = bettingContract.getNumberOfBets();
        assertEq(actualNumberOfBets, 4);
    }
}
