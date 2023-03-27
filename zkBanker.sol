// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ERC20/IERC20.sol";
import "./interfaces/ZKL/IZkSync.sol";
import "./utils/ERC20/SafeERC20.sol";
import "./access/Ownable.sol";

contract zkBanker is Ownable {
    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => uint8) public tokenDecimals;
    mapping(bytes32 => bool) private processedExits;
    

    event Deposit(address indexed user, address indexed token, uint256 amount, uint64 accountId);
    event Withdrawal(address indexed user, address indexed token, uint256 amount, uint64 accountId);

    constructor(address _zkSyncAddress) Ownable(_zkSyncAddress) {}

    function setTokenDecimals(address token, uint8 decimals) external onlyOwner {
        tokenDecimals[token] = decimals;
    }
    
    function depositERC20(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
    
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "Token transfer failed");
    
        balances[msg.sender][token] += balance;
        tokenDecimals[token] = IERC20(token).decimals();
        emit Deposit(msg.sender, token, balance);
    }


    function withdraw(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender][token] >= amount, "Insufficient balance");
    
        balances[msg.sender][token] -= amount;
        uint256 balance = IERC20(token).balanceOf(address(this));
    
        require(balance >= amount, "Insufficient contract balance");
    
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, token, amount);
    }


    function getBalance(address user, address token) public view returns (uint256) {
        uint64 accountId = zkSync.getAccountId(user);
        return zkSync.getBalance(accountId, token);
    }

    function balanceOf(address user, address token) public view returns (uint256) {
        if (token == address(0)) {
           return user.balance;
        } else {
           return balances[user][token] * (10 ** uint256(tokenDecimals[token]));
        }
    }

    function totalBalanceOf(address user) public view returns (uint256) {
        uint256 totalBalance = user.balance;
         for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 balance = balances[user][token] * (10 ** uint256(tokenDecimals[token]));
            totalBalance += balance;
         }
       return totalBalance;
    }


    function processExits(bytes32[] calldata _transferIds) public onlyOwner {
        for (uint256 i = 0; i < _transferIds.length; i++) {
            if (!processedExits[_transferIds[i]]) {
                zkSync.processExodusModeExit(_transferIds[i]);
                processedExits[_transferIds[i]] = true;
            }
        }
    }
}
