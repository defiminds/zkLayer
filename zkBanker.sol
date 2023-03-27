pragma solidity ^0.8.0;

import "https://github.com/defiminds/zkLayer/blob/zkbank/interfaces/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IZkSync {
    function depositERC20(
        address token,
        address depositTo,
        uint128 amount
    ) external returns (uint64);

    function depositETH(address depositTo) external payable returns (uint64);

    function requestFullExit(uint64 accountId, address token) external;

    function withdrawPendingBalance(uint64 accountId, address token) external;

    function getAccountId(address _address) external view returns (uint64);

    function getBalanceToWithdraw(
        uint64 _accountId,
        address _token
    ) external view returns (uint256);

    function getPendingBalance(uint64 _accountId, address _token)
        external
        view
        returns (uint256);

    function getL2DepositedERC20(address _zkSyncToken) external view returns (uint256);

    function getL2DepositedETH() external view returns (uint256);

    function isSigningBoxApproved(address _signingBox) external view returns (bool);

    function approveAndExecute(
        address _to,
        bytes calldata _data,
        uint256 _value,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes calldata _signature
    ) external returns (bytes memory);

    function zkSyncAddress() external view returns (address);
}

contract zkBanker is Ownable {
    mapping(address => mapping(address => uint256)) public balances;
    address public zkSyncAddress;

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event Transfered(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount
    );

    constructor(address _zkSyncAddress) {
        zkSyncAddress = _zkSyncAddress;
    }

    function deposit(address token, uint256 amount) external {
        IZkSync zkSync = IZkSync(zkSyncAddress);

        if (token == address(0)) {
            require(msg.value == amount, "zkBanker: deposit amount mismatch");
            zkSync.depositETH{value: msg.value}(address(this));
        } else {
            require(msg.value == 0, "zkBanker: non-zero ether deposit");
            require(
                IERC20(token).transferFrom(msg.sender, address(this), amount),
                "zkBanker: token transfer failed"
            );
            require(
                IERC20(token).approve(zkSyncAddress, amount),
                "zkBanker: token approval failed"
            );
            zkSync.depositERC20(token, address(this), uint128(amount));
        }

        balances[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) public {
        require(
            balances[msg.sender][token] >= amount,
            "zkBanker: insufficient balance"
        );
        balances[msg.sender][token] -= amount;
        IZkSync zkSync = IZkSync(zkSyncAddress);
        uint64 accountId = zkSync.getAccountId(msg.sender);

        uint256 balanceToWithdraw = zkSync.getBalanceToWithdraw(accountId, token);
        uint256 availableBalance = balances[msg.sender][token];

        if (balanceToWithdraw > 0) {
            require(
                balanceToWithdraw <= availableBalance,
                "zkBanker: insufficient balance for pending withdrawals"
            );
            zkSync.withdrawPendingBalance(accountId, token);
            balances[msg.sender][token] -= balanceToWithdraw;
            emit Withdrawn(msg.sender, token, balanceToWithdraw);
            return;
        }

        require(
            availableBalance >= amount,
            "zkBanker: insufficient balance for withdrawal"
        );

        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            require(
                IERC20(token).transfer(msg.sender, amount),
                "zkBanker: token transfer failed"
            );
        }

        balances[msg.sender][token] -= amount;
        emit Withdrawn(msg.sender, token, amount);
    }

    function transfer(
        address to,
        address token,
        uint256 amount
    ) public {
        require(
            balances[msg.sender][token] >= amount,
            "zkBanker: insufficient balance"
        );
        balances[msg.sender][token] -= amount;
        balances[to][token] += amount;

        emit Transfered(msg.sender, to, token, amount);
    }

    function balanceOf(address user, address token) public view returns (uint256) {
        IZkSync zkSync = IZkSync(zkSyncAddress);
        uint64 accountId = zkSync.getAccountId(user);
        return balances[user][token] + zkSync.getBalance(accountId, token);
    }
}
