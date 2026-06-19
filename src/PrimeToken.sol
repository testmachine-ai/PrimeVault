// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PrimeToken
 * @notice ERC20 token for the PrimeVault staking protocol
 */
contract PrimeToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Prime Token", "PRIME") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Mint new tokens (owner only)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
