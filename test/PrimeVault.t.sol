// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PrimeToken.sol";
import "../src/PrimeVault.sol";

contract PrimeVaultTest is Test {
    PrimeToken public token;
    PrimeVault public vault;

    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);

    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 constant REWARD_RATE = 1e14; // 0.0001 ETH per token per second

    function setUp() public {
        token = new PrimeToken(INITIAL_SUPPLY);
        vault = new PrimeVault(address(token));

        // Setup reward rate
        vault.setRewardRate(REWARD_RATE);

        // Fund vault with ETH rewards
        vault.depositRewards{value: 1000 ether}();

        // Give alice and bob some tokens
        token.transfer(alice, 10_000 ether);
        token.transfer(bob, 10_000 ether);
    }

    function test_Deposit() public {
        vm.startPrank(alice);
        token.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether);
        vm.stopPrank();

        assertEq(vault.getDeposit(alice), 1000 ether);
        assertEq(vault.totalDeposits(), 1000 ether);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        token.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether);

        // Advance time for rewards
        vm.warp(block.timestamp + 1 hours);

        uint256 balanceBefore = token.balanceOf(alice);
        vault.withdraw(1000 ether);
        uint256 balanceAfter = token.balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfter - balanceBefore, 1000 ether);
        assertEq(vault.getDeposit(alice), 0);
    }

    function test_RewardAccumulation() public {
        vm.startPrank(alice);
        token.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether);
        vm.stopPrank();

        // Advance time
        vm.warp(block.timestamp + 1 hours);

        uint256 pending = vault.pendingReward(alice);
        // 1000 tokens * 1e14 rate * 3600 seconds / 1e18 = 360 ETH
        assertEq(pending, 360 ether);
    }

    function test_MultipleDepositors() public {
        // Alice deposits
        vm.startPrank(alice);
        token.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether);
        vm.stopPrank();

        // Bob deposits
        vm.startPrank(bob);
        token.approve(address(vault), 500 ether);
        vault.deposit(500 ether);
        vm.stopPrank();

        assertEq(vault.totalDeposits(), 1500 ether);
        assertEq(vault.getDeposit(alice), 1000 ether);
        assertEq(vault.getDeposit(bob), 500 ether);
    }

    function test_ClaimRewards() public {
        vm.startPrank(alice);
        token.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether);

        vm.warp(block.timestamp + 1 hours);

        uint256 ethBefore = alice.balance;
        vault.claimRewards();
        uint256 ethAfter = alice.balance;
        vm.stopPrank();

        assertGt(ethAfter, ethBefore);
    }

    function test_OnlyOwnerCanSetRewardRate() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.setRewardRate(1e15);
    }

    function test_OnlyOwnerCanDepositRewards() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert();
        vault.depositRewards{value: 1 ether}();
    }

    receive() external payable {}
}
