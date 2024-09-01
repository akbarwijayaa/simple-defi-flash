// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DefiChanges {
    address private owner;
    uint256 private constant loanPercent = 5e17; // represent 0.5 in fixed
    AggregatorV3Interface internal dataFeed;

    struct Account {
        uint256 amount;
        uint256 amountLoan;
        uint256 availableAmountLoan;
        uint256 timestamp;
    }

    constructor(){
        owner = msg.sender;
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
    }

    mapping(address => Account) public accounts;
    event CollateralDeposited(address indexed user, uint256 amount, uint256 timestamp);
    event CollateralWithdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event LoanWithdraw(address indexed user, uint256 amount);

    function depositCollateral() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        Account storage account = accounts[msg.sender];
        account.amount += msg.value;
        account.availableAmountLoan += (msg.value * loanPercent)/1e18;
        account.timestamp = block.timestamp;

        emit CollateralDeposited(msg.sender, msg.value, block.timestamp);
    }

    function withdrawCollateral(uint256 withdrawAmount) external {
        Account storage account = accounts[msg.sender];
        uint256 amount = account.amount;
        require(amount > 0, "No collateral to withdraw");
        require(withdrawAmount > 0, "Withdrawal amount must be greater than zero");
        require(withdrawAmount <= amount, "Insufficient collateral to withdraw this amount");

        account.amount -= withdrawAmount;

        if (account.amount == 0) {
            account.timestamp = 0;
        }

        payable(msg.sender).transfer(withdrawAmount);

        emit CollateralWithdrawn(msg.sender, withdrawAmount, block.timestamp);
    }

    function getCollateral(address user) external view returns (uint256 amount, uint256 timestamp) {
        Account storage account = accounts[user];
        return (account.amount, account.timestamp);
    }

    function getAvailableAmountLoan(address user) external view returns (uint256 amount){
        Account storage account = accounts[user];
        return (account.availableAmountLoan);
    }

    function withdrawLoan(uint256 amount) external {
        Account storage account = accounts[msg.sender];
        require(account.availableAmountLoan > 0);

        account.amount -= amount;
        account.amountLoan += amount;
        account.availableAmountLoan -= amount;

        payable(msg.sender).transfer(amount);

        emit LoanWithdraw(msg.sender, amount);
    }

    function getEthPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        int amount = answer / 1e8;
        return amount;
    }


}
