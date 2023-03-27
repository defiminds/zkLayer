pragma solidity ^0.8.0;

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
