pragma solidity ^0.8.0;

import "./access/Ownable.sol";
import "./utils/math/SafeMath.sol";
import "./interfaces/ERC20/IERC20n.sol";

interface IZkSync {
    function getAccountId(address user) external view returns (uint64);
    function getBalance(uint64 accountId, address token) external view returns (uint256);
    function depositERC20(
        address token,
        uint128 amount,
        uint64 accountId
    ) external;
    function withdrawERC20(
        address token,
        uint128 amount,
        uint64 accountId
    ) external;
    function processExodusModeExit(uint32 tokenId) external;
}

contract zkBanker is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => mapping(address => uint256)) private lockedBalances;
    mapping(address => uint128) public tokenIds;
    event BalanceUnlocked(address indexed token, uint128 amount);

    IZkSync private zkSync;
    address private zkSyncAddress;

    constructor(address _zkSyncAddress) {
        zkSyncAddress = _zkSyncAddress;
        zkSync = IZkSync(zkSyncAddress);
    }

    function setZkSyncAddress(address _zkSyncAddress) external onlyOwner {
        zkSyncAddress = _zkSyncAddress;
        zkSync = IZkSync(zkSyncAddress);
    }

    function deposit(address token, uint128 amount) external {
        require(amount > 0, "zkBanker: cannot deposit 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint64 accountId = zkSync.getAccountId(msg.sender);
        zkSync.depositERC20(token, amount, accountId);
        balances[msg.sender][token] = balances[msg.sender][token].add(uint256(amount));
    }

    function withdraw(address token, uint128 amount) external {
        require(amount > 0, "zkBanker: cannot withdraw 0");
        uint64 accountId = zkSync.getAccountId(msg.sender);
        require(zkSync.getBalance(accountId, token) >= amount, "zkBanker: insufficient balance");
        zkSync.withdrawERC20(token, amount, accountId);
        IERC20(token).transfer(msg.sender, amount);
        balances[msg.sender][token] = balances[msg.sender][token].sub(uint256(amount));
    }

    function balanceOf(address user, address token) public view returns (uint256) {
        return balances[user][token];
    }

    function getLockedBalance(address user, address token) public view returns (uint256) {
        return lockedBalances[user][token];
    }

    function lockBalance(address token, uint128 amount) external {
        require(amount > 0, "zkBanker: cannot lock 0 balance");
        uint64 accountId = zkSync.getAccountId(msg.sender);
        require(zkSync.getBalance(accountId, token) >= amount, "zkBanker: insufficient balance");
        zkSync.withdrawERC20(token, amount, accountId);
        lockedBalances[msg.sender][token] = lockedBalances[msg.sender][token].add(uint256(amount));
    }

    function unlockBalance(address token, uint128 amount) external {
    require(msg.sender == owner(), "zkBanker: Only the owner can unlock the balance");
    // Withdraw from zkSync
    IZkSync zkSync = IZkSync(zkSyncAddress);
    uint64 accountId = zkSync.getAccountId(address(this));
    uint128 tokenId = tokenIds[token];
    // Update balance
    balances[address(this)][token] = balances[address(this)][token].sub(amount);
    balances[owner()][token] = balances[owner()][token].add(amount);
    emit BalanceUnlocked(token, amount);
    }
}
