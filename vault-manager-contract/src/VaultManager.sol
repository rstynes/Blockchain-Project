// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VaultManager {
    struct Vault {
        address owner;
        uint256 balance;
    }

    Vault[] public vaults;
    mapping(address => uint256[]) public vaultsByOwner;

    event VaultAdded(address indexed owner, uint256 indexed vaultId);
    event VaultDeposit(uint256 indexed vaultId, uint256 amount);
    event VaultWithdraw(uint256 indexed vaultId, uint256 amount);

    modifier onlyOwner(uint256 _vaultId) {
        require(msg.sender == vaults[_vaultId].owner, "Only the owner can perform this action");
        _;
    }

    function addVault() public returns (uint256 vaultId){
        Vault memory newVault = Vault(msg.sender, 0);
        vaults.push(newVault);
        //uint256 vaultId = vaults.length - 1;
        vaultsByOwner[msg.sender].push(vaultId);
        emit VaultAdded(msg.sender, vaultId);
    }

    function deposit(uint256 _vaultId) public payable onlyOwner(_vaultId) {
        vaults[_vaultId].balance += msg.value;
        emit VaultDeposit(_vaultId, msg.value);
    }

    function withdraw(uint256 _vaultId, uint256 _amount) public onlyOwner(_vaultId) {
        require(_amount <= vaults[_vaultId].balance, "Insufficient funds");
        vaults[_vaultId].balance -= _amount;
        payable(msg.sender).transfer(_amount);
        emit VaultWithdraw(_vaultId, _amount);
    }

    function getVault(uint256 _vaultId) public view returns (address, uint256 balance) {
        return (vaults[_vaultId].owner, vaults[_vaultId].balance);
    }

    function getVaultsLength() public view returns (uint256) {
        return vaults.length;
    }

    function getMyVaults() public view returns (uint256[] memory) {
        return vaultsByOwner[msg.sender];
    }
}
