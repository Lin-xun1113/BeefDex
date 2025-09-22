// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniswapV3Manager {
    struct MintParams {
        address poolAddress;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min; //经过滑点计算后的边界值
        uint256 amount1Min;
    }
}
