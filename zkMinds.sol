// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importing Polygon SDK
import { Matic } from "@maticnetwork/maticjs";
import { IDepositManager } from "./IDepositManager.sol";
import { IWETH } from "./interfaces.sol";
import { QuickSwap } from "./QuickSwap.sol";

// ERC20 implementation
contract MyERC20 is ERC20, Ownable {

    // Polygon contracts and addresses
    IDepositManager public constant depositManager = IDepositManager(0x7d284aaac6E9257B087eE90E82B6dC00dEe0269b);
    QuickSwap public constant quickSwap = QuickSwap(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    IWETH public constant weth = IWETH(0x4dF4F0Db4b435c5e616c0dB61616f796cAb3f2F9);
    Matic public matic;

    constructor(address _matic) ERC20("MyToken", "MYT") {
        matic = Matic(_matic);
        _mint(msg.sender, 111_000_000 * 10**18);
    }

    // Deposit tokens into the contract using Polygon DepositManager
    function depositTokens(address token, uint amount) external {
        // Approve token transfer to DepositManager
        IERC20(token).approve(address(depositManager), amount);
        // Deposit tokens using DepositManager
        depositManager.depositFor(msg.sender, token, abi.encode(amount));
    }

    // Swap tokens using QuickSwap DEX
    function swapTokens(address fromToken, address toToken, uint amount) external {
        // Approve token transfer to QuickSwap
        IERC20(fromToken).approve(address(quickSwap), amount);
        // Swap tokens using QuickSwap
        quickSwap.swapExactTokensForTokens(amount, 0, fromToken, toToken, msg.sender, block.timestamp);
    }

    // Burn tokens
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

    // Transfer ownership of the contract
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // Wrap and unwrap ETH using Polygon WETH
    receive() external payable {
        weth.deposit{value: msg.value}();
    }
    function withdrawEther() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    function unwrapEther(uint amount) external {
        weth.withdraw(amount);
    }

    // Deposit and withdraw tokens from Polygon
    function depositMatic() external onlyOwner {
        matic.deposit{value: address(this).balance}();
    }
    function withdrawMatic() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
    function depositToken(address token, uint amount) external onlyOwner {
        IERC20(token).approve(address(matic), amount);
        matic.approveERC20ForDeposit(token, amount);
        matic.depositERC20ForUser(token, msg.sender, amount);
    }
    function withdrawToken(address token,uint amount) external onlyOwner {
        matic.withdrawERC20(token, amount, msg.sender);
    }
}
