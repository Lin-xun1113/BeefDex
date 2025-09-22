// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "./UniswapV3Pool.Utils.t.sol";

import "../src/interfaces/IUniswapV3Pool.sol";
import "../src/lib/LiquidityMath.sol";
import "../src/lib/TickMath.sol";
import "../src/UniswapV3Pool.sol";

import "forge-std/console.sol";

contract UniswapV3PoolSwapsTest is Test, UniswapV3PoolUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;

    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;
    bytes extra;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH");
        token1 = new ERC20Mintable("USDC", "USDC");

        extra = encodeExtra(address(token0), address(token1), address(this));
    }

    //  单个价格范围测试
    //          5000
    //  4545 -----|----- 5500
    //
    // TODO: 测试购买ETH（用USDC换ETH）
    // 提示：
    // 1. 设置流动性范围 4545-5500，当前价格5000
    // 2. 用42 USDC购买ETH
    // 3. 验证交换后的余额变化
    // 4. 验证池子的新价格和tick
    // 预期结果参考：
    // - 用户应该获得约 0.008371593947078348 ETH
    // - 池子价格应该下降（因为卖出ETH）
    function testBuyETHOnePriceRange() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试卖出ETH（用ETH换USDC）
    // 提示：
    // 1. 同样的流动性设置
    // 2. 卖出ETH换取USDC
    // 3. 验证余额和价格变化方向相反
    function testSellETHOnePriceRange() public {
        // TODO: 实现测试逻辑
    }

    //  两个价格范围测试
    //          5000
    //  4545 -----|----- 5500
    //  4000 ----------- 6250
    //
    // TODO: 测试跨多个价格范围的交换
    // 提示：
    // 1. 添加两个重叠的流动性范围
    // 2. 执行大额交换，使价格跨越多个tick
    // 3. 验证流动性在不同价格点的变化
    function testBuyETHTwoLiquidityRanges() public {
        // TODO: 实现测试逻辑
    }

    //  价格范围之间有间隙
    //        5000
    //   4545 --|- 5050
    //             5150 -- 5500
    //
    // TODO: 测试交换穿过没有流动性的价格区间
    // 提示：
    // 1. 创建两个不连续的流动性范围
    // 2. 执行交换使价格穿过间隙
    // 3. 验证在没有流动性的区间价格如何变化
    function testBuyETHLiquidityGap() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试买入ETH但只获得部分数量
    // 提示：
    // 1. 尝试购买大量ETH，超过池子能提供的
    // 2. 验证实际获得的数量小于预期
    // 3. 检查价格达到了范围边界
    function testBuyETHNotEnoughLiquidity() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试卖出ETH但只能卖出部分
    // 提示：
    // 1. 尝试卖出大量ETH
    // 2. 验证实际卖出的数量受限
    function testSellETHNotEnoughLiquidity() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试无效的价格限制
    // 提示：
    // 1. 买入时设置过高的价格限制
    // 2. 卖出时设置过低的价格限制
    // 3. 使用vm.expectRevert验证交易失败
    function testInvalidPriceLimit() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试不转移代币时的失败
    // 提示：
    // 1. 设置transferInSwapCallback = false
    // 2. 预期交易因余额不足而失败
    function testFailSwapInsufficientBalances() public {
        // TODO: 实现测试逻辑
    }

    // 回调函数
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        if (transferInMintCallback) {
            IUniswapV3Pool.CallbackData memory extra_ = abi.decode(
                data,
                (IUniswapV3Pool.CallbackData)
            );

            token0.mint(msg.sender, amount0);
            token1.mint(msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        if (transferInSwapCallback) {
            // TODO: 实现交换回调
            // 提示：只转移amount > 0的代币
        }
    }

    // 基础setupTestCase实现 - Pool.Swaps测试专用
    function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        // Step 1: 铸造代币
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        // Step 2: 创建Pool
        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            sqrtP(params.currentPrice),
            tick(params.currentPrice)
        );

        // Step 3: 如果需要，添加流动性
        if (params.mintLiqudity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < params.liquidity.length; i++) {
                (poolBalance0Tmp, poolBalance1Tmp) = pool.mint(
                    address(this),
                    params.liquidity[i].lowerTick,
                    params.liquidity[i].upperTick,
                    params.liquidity[i].amount,
                    extra
                );
                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }

        // Step 4: 设置回调标志
        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
    }
}
