// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQuickSwapFactory {
function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IQuickSwapPair {
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
function token0() external view returns (address);
function token1() external view returns (address);
}

interface IWETH {
function deposit() external payable;
function withdraw(uint wad) external;
}

// QuickSwap DEX implementation
contract QuickSwap {
address public constant factoryAddress = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
address public constant wethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
IWETH public immutable WETH;
IQuickSwapFactory public immutable factory;

constructor() {
    WETH = IWETH(wethAddress);
    factory = IQuickSwapFactory(factoryAddress);
}

// Swap tokens on QuickSwap
function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address tokenIn,
    address tokenOut,
    address to,
    uint deadline
) external {
    IQuickSwapPair pair = IQuickSwapPair(factory.getPair(tokenIn, tokenOut));
    IERC20(tokenIn).transferFrom(msg.sender, address(pair), amountIn);
    _swap(pair, amountOutMin, to, deadline);
}

function _swap(
    IQuickSwapPair pair,
    uint amountOutMin,
    address to,
    uint deadline
) internal {
    uint amountIn = IERC20(pair.token0()).balanceOf(address(pair));
    uint amountOut = _getAmountOut(amountIn, pair.token0(), pair.token1());
    require(amountOut >= amountOutMin, "QuickSwap: INSUFFICIENT_OUTPUT_AMOUNT");
    (uint amount0Out, uint amount1Out) = pair.token0() == address(WETH)
        ? (uint(0), amountOut)
        : (amountOut, uint(0));
    bytes memory data;
    pair.swap(amount0Out, amount1Out, to, data);
}

function _getAmountOut(uint amountIn, address tokenIn, address tokenOut) internal view returns (uint amountOut) {
    require(tokenIn != tokenOut, "QuickSwap: IDENTICAL_ADDRESSES");
    address pair = factory.getPair(tokenIn, tokenOut);
    require(pair != address(0), "QuickSwap: PAIR_NOT_FOUND");
    (uint reserveIn, uint reserveOut) = tokenIn < tokenOut
        ? (IERC20(tokenIn).balanceOf(pair), IERC20(tokenOut).balanceOf(pair))
        : (IERC20(tokenOut).balanceOf(pair), IERC20(tokenIn).balanceOf(pair));
    require(reserveIn > 0 && reserveOut > 0, "QuickSwap: INSUFFICIENT_LIQUIDITY");
    amountOut = (amountIn * reserveOut) / reserveIn;
}
}
