// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ZKL/IZkSync.sol";

contract Ownable {
    address private _owner;
    address private _newOwner;

    IZkSync private zkSync;
    address private zkSyncAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _zkSyncAddress) {
        zkSyncAddress = _zkSyncAddress;
        zkSync = IZkSync(zkSyncAddress);
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _newOwner = newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function balanceOf(address user, address token) public view returns (uint256) {
        uint64 accountId = zkSync.getAccountId(user);
        return zkSync.getBalance(accountId, token);
    }
}
