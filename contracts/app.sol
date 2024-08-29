// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DefiChanges {
    address private owner;
    struct Collateral {
        uint256 amount;
        uint256 timestamp;
    }

    constructor(){
        owner = msg.sender;
    }

    mapping(address => Collateral) public collaterals;
    event CollateralDeposited(address indexed user, uint256 amount, uint256 timestamp);
    event CollateralWithdrawn(address indexed user, uint256 amount, uint256 timestamp);

    function depositCollateral() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        Collateral storage collateral = collaterals[msg.sender];
        collateral.amount += msg.value;
        collateral.timestamp = block.timestamp;

        emit CollateralDeposited(msg.sender, msg.value, block.timestamp);
    }

    function withdrawCollateral(uint256 withdrawAmount) external {
        Collateral storage collateral = collaterals[msg.sender];
        uint256 amount = collateral.amount;
        require(amount > 0, "No collateral to withdraw");
        require(withdrawAmount > 0, "Withdrawal amount must be greater than zero");
        require(withdrawAmount <= amount, "Insufficient collateral to withdraw this amount");

        collateral.amount -= withdrawAmount;

        if (collateral.amount == 0) {
            collateral.timestamp = 0;
        }

        payable(msg.sender).transfer(withdrawAmount);

        emit CollateralWithdrawn(msg.sender, withdrawAmount, block.timestamp);
    }

    function getCollateral(address user) external view returns (uint256 amount, uint256 timestamp) {
        Collateral storage collateral = collaterals[user];
        return (collateral.amount, collateral.timestamp);
    }
}
