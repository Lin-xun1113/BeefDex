// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LiquidityMath.sol";

library Tick {
    struct Info {
        bool initialized;
        // 跟踪一个tick拥有的绝对流动性数量。它用来跟踪一个 tick 是否还可用
        uint128 liquidityGross;
        // 有符号整数，用来跟踪当跨越 tick 时添加/移除的流动性数量
        int128 liquidityNet;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int128 liquidityDelta,
        bool upper
    ) internal returns (bool flipped) {
        Tick.Info storage tickInfo = self[tick];

        uint128 liquidityBefore = tickInfo.liquidityGross;
        uint128 liquidityAfter = LiquidityMath.addLiquidity(
            liquidityBefore,
            liquidityDelta
        );

        flipped = (liquidityAfter == 0) != (liquidityBefore == 0);

        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidityGross = liquidityAfter;
        tickInfo.liquidityNet = upper
            ? int128(int256(tickInfo.liquidityNet) - int256(liquidityDelta))
            : int128(int256(tickInfo.liquidityNet) + int256(liquidityDelta));
    }

    function cross(mapping(int24 => Tick.Info) storage self, int24 tick)
        internal
        view
        returns (int128 liquidityDelta)
    {
        Tick.Info storage info = self[tick];
        liquidityDelta = info.liquidityNet;
    }
}