// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IDepositManager {
    function depositEtherFor(address user) external payable;
    function depositFor(address user, address rootToken, bytes calldata depositData) external;
    function tokenToType(address rootToken) external view returns (uint16);
}
