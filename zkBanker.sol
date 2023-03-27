// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/ZKL/IZkSync.sol";
import "./interfaces/ERC20/IERC20.sol";
import "./utils/ERC20/SafeERC20.sol";
import "./utils/math/SafeMath.sol";

contract zkBanker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable zkSyncAddress;
    address public immutable maticAddress;
    address public immutable wbtcAddress;

    mapping(address => mapping(address => uint256)) public balances;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event Transfer(address indexed from, address indexed to, address indexed token, uint256 amount);

    constructor(address _zkSyncAddress, address _maticAddress, address _wbtcAddress) {
        zkSyncAddress = _zkSyncAddress;
        maticAddress = _maticAddress;
        wbtcAddress = _wbtcAddress;
    }

    function deposit(address token, uint256 amount) external {
        IZkSync zkSync = IZkSync(zkSyncAddress);
        require(token == maticAddress || token == wbtcAddress, "Invalid token");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(zkSyncAddress, amount);
        uint64 accountId = zkSync.getAccountId(msg.sender);

        if (accountId == 0) {
            accountId = zkSync.createAccount();
            zkSync.setAccountOnchainPubkey(accountId);
            zkSync.setAccountCommitment(accountId);
        }

        zkSync.depositERC20(token, accountId, amount);
        balances[msg.sender][token] = balances[msg.sender][token].add(amount);

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        IZkSync zkSync = IZkSync(zkSyncAddress);
        require(token == maticAddress || token == wbtcAddress, "Invalid token");

        uint64 accountId = zkSync.getAccountId(msg.sender);
        require(accountId != 0, "Account not found");

        zkSync.withdrawERC20(token, accountId, amount);
        IERC20(token).safeTransfer(msg.sender, amount);
        balances[msg.sender][token] = balances[msg.sender][token].sub(amount);

        emit Withdraw(msg.sender, token, amount);
    }

    function transfer(address token, address to, uint256 amount) external {
        IZkSync zkSync = IZkSync(zkSyncAddress);
        require(token == maticAddress || token == wbtcAddress, "Invalid token");

        uint64 accountId = zkSync.getAccountId(msg.sender);
        require(accountId != 0, "Account not found");

        zkSync.transferERC20(token, accountId, to, amount);
        balances[msg.sender][token] = balances[msg.sender][token].sub(amount);
        balances[to][token] = balances[to][token].add(amount);

        emit Transfer(msg.sender, to, token, amount);
    }

    function getBalance(address user, address token) public view returns (uint256) {
        IZkSync zkSync = IZkSync(zkSyncAddress);
        uint64 accountId = zkSync.getAccountId(user);

        if (accountId != 0) {
            return zkSync.getBalanceToWithdraw(accountId, token).add(balances[user][token]);
        } else {
            return balances[user][token];
        }
    }

    function withdrawAll(address token) external {
        uint256 balance = getBalance(msg.sender, token);
        withdraw(token, balance);
    }
}
