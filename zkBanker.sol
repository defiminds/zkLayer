// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ERC20/IERC20.sol";
import "./access/Ownable.sol";
import "./interfaces/ZKL/IZkSync.sol";

contract zkBanker is Ownable {
    mapping(address => mapping(address => uint256)) private balances;
    mapping(bytes32 => bool) private processedExits;

    event Deposit(address indexed user, address indexed token, uint256 amount, uint64 accountId);
    event Withdrawal(address indexed user, address indexed token, uint256 amount, uint64 accountId);

    constructor(address _zkSyncAddress) Ownable(_zkSyncAddress) {}

    function deposit(address token, uint256 amount) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint64 accountId = zkSync.getAccountId(msg.sender);

        IERC20(token).approve(zkSyncAddress, amount);
        zkSync.depositERC20(token, amount, accountId);

        balances[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount, accountId);
    }

    function withdraw(address token, uint256 amount) public {
        require(balances[msg.sender][token] >= amount, "zkBanker: insufficient balance");

        uint64 accountId = zkSync.getAccountId(msg.sender);

        bytes32 _transferId = zkSync.withdrawPendingBalance(token, amount, accountId);
        processedExits[_transferId] = true;

        balances[msg.sender][token] -= amount;

        emit Withdrawal(msg.sender, token, amount, accountId);
    }

    function getBalance(address user, address token) public view returns (uint256) {
        uint64 accountId = zkSync.getAccountId(user);
        return zkSync.getBalance(accountId, token);
    }

    function balanceOf(address user, address token) public view returns (uint256) {
        return balances[user][token] + getBalance(user, token);
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
