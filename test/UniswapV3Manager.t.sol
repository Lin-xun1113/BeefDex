// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Test, stdError} from "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "./TestUtils.sol";

import "../src/lib/LiquidityMath.sol";
import "../src/UniswapV3Manager.sol";

contract UniswapV3ManagerTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;
    UniswapV3Manager manager;

    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;
    bytes extra;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH");
        token1 = new ERC20Mintable("USDC", "USDC");
        manager = new UniswapV3Manager();

        extra = encodeExtra(address(token0), address(token1), address(this));
    }

    // TODO: 测试通过Manager在范围内铸造流动性
    // 提示：
    // 1. 使用IUniswapV3Manager.MintParams结构体
    // 2. 测试滑点保护功能
    // 3. 验证Manager正确调用了Pool合约
    function testMintInRange() public {
        // TODO: 实现测试逻辑
        // 创建MintParams数组
        // 设置测试参数
        // 验证铸造后的余额
    }

    // TODO: 测试滑点保护 - 成功情况
    // 提示：
    // 1. 设置合理的amount0Min和amount1Min
    // 2. 验证交易成功完成
    function testMintRangeSlippageProtectionSuccess() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试滑点保护 - 失败情况
    // 提示：
    // 1. 设置过高的amount0Min或amount1Min
    // 2. 使用vm.expectRevert预期SlippageCheckFailed错误
    function testMintRangeSlippageProtectionFail() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试通过Manager执行交换
    // 提示：
    // 1. 先添加流动性
    // 2. 通过manager.swap执行交换
    // 3. 验证Manager正确处理了回调
    function testSwapBuyETH() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试反向交换（卖ETH）
    function testSwapSellETH() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试交换时的滑点限制
    // 提示：
    // 1. 设置sqrtPriceLimitX96参数
    // 2. 验证价格不会超过限制
    function testSwapWithPriceLimit() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试多个流动性位置
    // 提示：
    // 1. 通过Manager添加多个不同范围的流动性
    // 2. 验证每个位置独立跟踪
    function testMintMultiplePositions() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试未授权的回调调用
    // 提示：
    // 1. 直接调用Manager的回调函数
    // 2. 验证只有Pool合约可以调用回调
    function testUnauthorizedCallback() public {
        // TODO: 实现测试逻辑
    }

    // 辅助函数：创建MintParams
    function mintParams(
        int24 lowerTick,
        int24 upperTick,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (IUniswapV3Manager.MintParams memory) {
        return IUniswapV3Manager.MintParams({
            poolAddress: address(pool),
            lowerTick: lowerTick,
            upperTick: upperTick,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0
        });
    }

    // 辅助函数：设置测试环境
    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint256 currentPrice;
        IUniswapV3Manager.MintParams[] mints;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiqudity;
    }

    function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            sqrtP(params.currentPrice),
            tick(params.currentPrice)
        );

        if (params.mintLiqudity) {
            token0.approve(address(manager), params.wethBalance);
            token1.approve(address(manager), params.usdcBalance);

            // 通过Manager铸造流动性
            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < params.mints.length; i++) {
                params.mints[i].poolAddress = address(pool);
                (poolBalance0Tmp, poolBalance1Tmp) = manager.mint(
                    params.mints[i]
                );
                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
        
        poolBalance0 = token0.balanceOf(address(pool));
        poolBalance1 = token1.balanceOf(address(pool));
    }
}
