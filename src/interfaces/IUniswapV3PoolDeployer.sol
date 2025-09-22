// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniswapV3PoolDeployer {
    struct PoolParameter {
        address factory,
        address token0,
        address token1,
        uint24 tickspacing
        
    }

    function createPool(
        address tokenX,
        address tokenY,
        uint24 tickSpacing
    ) public returns (address pool);
}