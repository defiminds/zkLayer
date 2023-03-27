// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/defiminds/zkLayer/blob/zkbank/interfaces/ERC20/IERC20.sol";
import "https://github.com/defiminds/zkLayer/blob/zkbank/utils/ERC20/SafeERC20.sol";
import "https://github.com/defiminds/zkLayer/blob/zkbank/utils/math/SafeMath.sol";

contract ZkLayer {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    address public constant MATIC_ADDRESS = 0x742d35Cc6634C0532925a3b844Bc454e4438f44e; //MATIC token address on Mumbai testnet
    address public constant WETH_ADDRESS = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; //WETH token address on Mumbai testnet
    event Deposit(address indexed user, uint256 amount, address indexed token);
    event Withdrawal(address indexed user, uint256 amount, address indexed token);

    function deposit(uint256 amount, address token) external {
        require(token == MATIC_ADDRESS || token == WETH_ADDRESS, "Unsupported token");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit Deposit(msg.sender, amount, token);
    }

    function withdraw(uint256 amount, address token) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(token == MATIC_ADDRESS || token == WETH_ADDRESS, "Unsupported token");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount, token);
    }
}
