// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PrimeVault
 * @notice Staking vault that accepts PRIME tokens and distributes ETH rewards
 * @dev Users deposit PRIME tokens to earn a share of ETH rewards deposited by the owner
 * @custom:scan-test billing-fix validation run 2026-06-19 (epoch 5)
 */
contract PrimeVault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastClaimTime;

    uint256 public totalDeposits;
    uint256 public rewardRatePerSecond; // ETH reward per token per second (scaled by 1e18)

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event RewardsDeposited(uint256 amount);

    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @notice Deposit PRIME tokens into the vault
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Cannot deposit zero");

        // Claim any pending rewards first
        if (deposits[msg.sender] > 0) {
            _claimRewards(msg.sender);
        }

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] += amount;
        totalDeposits += amount;
        lastClaimTime[msg.sender] = block.timestamp;

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw tokens and claim accumulated rewards
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw zero");
        require(deposits[msg.sender] >= amount, "Insufficient deposit");

        uint256 reward = pendingReward(msg.sender);

        // Update state before external interactions (checks-effects-interactions)
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        lastClaimTime[msg.sender] = block.timestamp;

        // Transfer ETH rewards to user
        if (reward > 0 && address(this).balance >= reward) {
            (bool success, ) = msg.sender.call{value: reward}("");
            require(success, "Reward transfer failed");
        }

        // Return staked tokens
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount, reward);
    }

    /**
     * @notice Claim rewards without withdrawing tokens
     */
    function claimRewards() external {
        require(deposits[msg.sender] > 0, "No deposits");
        _claimRewards(msg.sender);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user Address to check
     * @return Pending ETH reward amount
     */
    function pendingReward(address user) public view returns (uint256) {
        if (deposits[user] == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastClaimTime[user];
        return (deposits[user] * rewardRatePerSecond * timeElapsed) / 1e18;
    }

    /**
     * @notice Get user's current deposit
     * @param user Address to check
     * @return Deposited amount
     */
    function getDeposit(address user) external view returns (uint256) {
        return deposits[user];
    }

    /**
     * @notice Update reward rate (owner only)
     * @param newRate New reward rate per second (scaled by 1e18)
     */
    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    /**
     * @notice Deposit ETH rewards into the vault (owner only)
     */
    function depositRewards() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH");
        emit RewardsDeposited(msg.value);
    }

    /**
     * @notice Withdraw ETH reward balance from the vault to a recipient
     * @param to Recipient of the ETH
     * @param amount Amount of ETH to send
     */
    function adminWithdraw(address to, uint256 amount) external {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Internal function to claim rewards
     */
    function _claimRewards(address user) internal {
        uint256 reward = pendingReward(user);

        if (reward > 0 && address(this).balance >= reward) {
            lastClaimTime[user] = block.timestamp;
            (bool success, ) = user.call{value: reward}("");
            require(success, "Reward transfer failed");
        } else {
            lastClaimTime[user] = block.timestamp;
        }
    }

    receive() external payable {}
}
