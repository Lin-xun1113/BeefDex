// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./TestUtils.sol";
import "../src/lib/LiquidityMath.sol";

abstract contract UniswapV3PoolUtils is Test, TestUtils {
    struct LiquidityRange {
        int24 lowerTick;
        int24 upperTick;
        uint128 amount;
    }

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint256 currentPrice;
        LiquidityRange[] liquidity;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiqudity;
    }

    function liquidityRange(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1,
        uint256 currentPrice
    ) internal pure returns (LiquidityRange memory range) {
        range = LiquidityRange({
            lowerTick: tick(lowerPrice),
            upperTick: tick(upperPrice),
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP(currentPrice), sqrtP(lowerPrice), sqrtP(upperPrice), amount0, amount1
            )
        });
    }

    function liquidityRange(uint256 lowerPrice, uint256 upperPrice, uint128 amount)
        internal
        pure
        returns (LiquidityRange memory range)
    {
        range = LiquidityRange({lowerTick: tick(lowerPrice), upperTick: tick(upperPrice), amount: amount});
    }

    // setupTestCase 必须在具体的测试合约中实现
    // 因为它需要访问具体测试合约中定义的变量（如pool, token0, token1等）
    // 这个函数会：
    // 1. 铸造代币给测试合约
    // 2. 创建并初始化Pool
    // 3. 如果需要，添加流动性
    // 4. 返回池子中的代币余额
}
