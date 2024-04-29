// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script, console2} from "forge-std/Script.sol";
import "../src/VaultManager.sol";

contract VaultManagerScript is Script {
function setUp() public {}

function run() public {
uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
vm.startBroadcast(deployerPrivateKey);
VaultManager ctr = new VaultManager();
vm.stopBroadcast();
}
}
