// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console} from "forge-std/Test.sol";
import { VaultManager } from "../src/VaultManager.sol";

contract VaultManagerTest is Test {
    VaultManager public vaultManager;
    
    
    address public alice;
    address public bob;
    address public carol;

    function setUp() public {
        vaultManager = new VaultManager();
        
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
        carol = makeAddr("Carol");
    }
    
function test_AddVault() public {
    // Alice adds a vault
    vm.startPrank(alice);
    vaultManager.addVault();
    vm.stopPrank();
}

function test_Deposit() public {
        vm.startPrank(alice);
        vm.deal(alice, 100);
        
        vaultManager.addVault();

        bytes memory fnCall = abi.encodeWithSignature("deposit(uint256)", 0);
        (bool okay, ) = address(vaultManager).call{value: 100}(fnCall);

        assertEq(true, okay);

        (,uint256 balance) = vaultManager.getVault(0);

        assertEq(balance, 100);
        vm.stopPrank();
}

function test_Withdraw() public {
    vm.startPrank(alice);
    vm.deal(alice, 100);
    vaultManager.addVault();

    bytes memory fnCallDeposit = abi.encodeWithSignature("deposit(uint256)", 0);
    (bool okayDeposit, ) = address(vaultManager).call{value: 100}(fnCallDeposit);
    assertEq(okayDeposit, true);

    bytes memory fnCallWithdraw = abi.encodeWithSignature("withdraw(uint256,uint256)", 0, 50);
    (bool okayWithdraw, ) = address(vaultManager).call(fnCallWithdraw);
    assertEq(okayWithdraw, true);

    (, uint256 balanceAfterWithdraw) = vaultManager.getVault(0);
    assertEq(balanceAfterWithdraw, 50);
    vm.stopPrank();
}

function test_MultipleVaults() public {
    vm.startPrank(alice);
    vm.deal(alice, 100);
    uint256 aliceVaultId = vaultManager.addVault();

    vm.startPrank(bob);
    vm.deal(bob, 50);
    uint256 bobVaultId = vaultManager.addVault();

    vm.startPrank(carol);
    vm.deal(carol, 20);
    uint256 carolVaultId = vaultManager.addVault();

    // Ensure correct number of vaults
    assertEq(vaultManager.getVaultsLength(), 3);
    
    // Ensure vaults are owned by correct addresses
    uint256[] memory aliceVaults = vaultManager.getMyVaults();
    assertEq(aliceVaults.length, 1);
    assertEq(aliceVaults[0], aliceVaultId);

    uint256[] memory bobVaults = vaultManager.getMyVaults();
    assertEq(bobVaults.length, 1);
    assertEq(bobVaults[0], bobVaultId);

    uint256[] memory carolVaults = vaultManager.getMyVaults();
    assertEq(carolVaults.length, 1);
    assertEq(carolVaults[0], carolVaultId);

    vm.stopPrank();
}

function test_GetVault() public {
    vm.startPrank(alice);
    uint256 vaultId = vaultManager.addVault();
    uint256 depositAmount = 100; 
    vm.deal(alice, depositAmount);
    vaultManager.deposit{value: depositAmount}(vaultId); 
    vm.stopPrank();
    
    (address owner, uint256 balance) = vaultManager.getVault(vaultId);
    assertEq(owner, alice);
    assertEq(balance, depositAmount);
}

function test_GetVaultsLength() public {
    vm.startPrank(alice);
    vaultManager.addVault();
    vaultManager.addVault();
    vm.stopPrank();

    uint256 length = vaultManager.getVaultsLength();

    assertEq(length, 2, "Vaults length should be 2");
}

function test_GetMyVaults() public {
    vm.startPrank(alice);
    vaultManager.addVault();

    uint256[] memory aliceVaults = vaultManager.getMyVaults();

    assertEq(aliceVaults.length, 1, "Alice should have one vault");
    vm.stopPrank();
}

function test_AliceWithdrawFromBobVault() public {
    vm.startPrank(alice);
    vaultManager.addVault();
    vm.stopPrank();

    vm.startPrank(bob);
    vaultManager.addVault();
    uint256 bobVaultId = vaultManager.getMyVaults()[0];
    vm.stopPrank();

    uint256 bobBalanceBefore = address(vaultManager).balance;

    bytes memory fnCall = abi.encodeWithSignature("withdraw(uint256,uint256)", bobVaultId, 50);
    (bool success, ) = address(vaultManager).call(fnCall);

    uint256 bobBalanceAfter = address(vaultManager).balance;

    assertEq(success, false, "Alice should not be able to withdraw from Bob's vault");

    assertEq(bobBalanceAfter, bobBalanceBefore, "Bob's vault balance should remain unchanged");
}

function test_CarolAttemptToDepositIntoAliceVault() public {
    // Alice adds a vault
    vm.startPrank(alice);
    vaultManager.addVault();
    uint256 aliceVaultId = vaultManager.getMyVaults()[0];
    vm.stopPrank();

    // Get Alice's vault balance before Carol's deposit attempt
    uint256 aliceBalanceBefore = address(vaultManager).balance;

    // Carol adds a vault
    vm.startPrank(carol);
    vaultManager.addVault();
    vm.stopPrank();

    // Carol attempts to deposit into Alice's vault
    bytes memory fnCall = abi.encodeWithSignature("deposit(uint256)", aliceVaultId);
    (bool success, ) = address(vaultManager).call{value: 100}(fnCall);

    // Get Alice's vault balance after Carol's deposit attempt
    uint256 aliceBalanceAfter = address(vaultManager).balance;

    // Assert that Carol's deposit attempt failed
    assertEq(success, false, "Carol should not be able to deposit into Alice's vault");

    // Assert that Alice's vault balance remained unchanged
    assertEq(aliceBalanceAfter, aliceBalanceBefore, "Alice's vault balance should remain unchanged");
}


function test_WithdrawMoreThanVaultBalance() public {
    // Alice adds a vault
    vm.startPrank(alice);
    uint256 aliceVaultId = vaultManager.addVault();
    vm.stopPrank();

    // Alice deposits 1 ether into her vault
    uint256 depositAmount = 1 ether;
    vm.startPrank(alice);
    vm.deal(alice, 1 ether);
    vaultManager.deposit{value: depositAmount}(aliceVaultId);
    vm.stopPrank();

    // Get Alice's vault balance before withdrawal attempt
    uint256 aliceBalanceBefore = address(vaultManager).balance;

    // Attempt to withdraw 1.5 ether from Alice's vault (more than the balance)
    bytes memory fnCallWithdraw = abi.encodeWithSignature("withdraw(uint256,uint256)", aliceVaultId, 1.5 ether);
    (bool withdrawSuccess, ) = address(vaultManager).call(fnCallWithdraw);

    // Get Alice's vault balance after withdrawal attempt
    uint256 aliceBalanceAfter = address(vaultManager).balance;

    // Assert that the withdrawal failed
    assertEq(withdrawSuccess, false, "Withdrawal should fail due to insufficient balance");

    // Assert that Alice's vault balance remains unchanged
    assertEq(aliceBalanceAfter, aliceBalanceBefore, "Alice's vault balance should remain unchanged");
}

function test_DepositIntoNonexistentVault() public {
    // Carol attempts to deposit into a nonexistent vault
    (bool success, ) = address(vaultManager).call{value: 100}(abi.encodeWithSignature("deposit(uint256)", 999)); // Nonexistent vault ID
    assertEq(success, false, "Deposit should fail as the vault ID doesn't exist");
}

function test_WithdrawFromNonexistentVault() public {
    // Bob attempts to withdraw from a nonexistent vault
    (bool success, ) = address(vaultManager).call{value: 100}(abi.encodeWithSignature("withdraw(uint256,uint256)", 999, 100 ether)); // Nonexistent vault ID
    assertEq(success, false, "Withdrawal should fail as the vault ID doesn't exist");
}

function test_WithdrawFromEmptyVault() public {
    // Alice adds a vault
    vm.startPrank(alice);
    vaultManager.addVault();
    uint256 aliceVaultId = vaultManager.getMyVaults()[0];
    vm.stopPrank();

    // Alice attempts to withdraw from an empty vault
    (bool success, ) = address(vaultManager).call{value: 100}(abi.encodeWithSignature("withdraw(uint256,uint256)", aliceVaultId, 100 ether));
    assertEq(success, false, "Withdrawal should fail as the vault is empty");
}