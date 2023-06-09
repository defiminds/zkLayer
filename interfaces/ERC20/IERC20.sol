// SPDX-License-Identifier: MIT
// ChatGPT IA (Boostraper,Helper,Debugger)
// DeFiMinds (Constructor, Updater)

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}
