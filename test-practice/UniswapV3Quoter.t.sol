// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "../src/UniswapV3Quoter.sol";
import "../src/UniswapV3Pool.sol";
import "../src/UniswapV3Manager.sol";
import "./ERC20Mintable.sol";
import "./TestUtils.sol";

contract UniswapV3QuoterTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;
    UniswapV3Manager manager;
    UniswapV3Quoter quoter;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);

        uint256 wethBalance = 100 ether;
        uint256 usdcBalance = 1000000 ether;

        token0.mint(address(this), wethBalance);
        token1.mint(address(this), usdcBalance);

        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            sqrtP(5000),
            tick(5000)
        );

        manager = new UniswapV3Manager();

        token0.approve(address(manager), wethBalance);
        token1.approve(address(manager), usdcBalance);

        // 添加初始流动性
        manager.mint(
            IUniswapV3Manager.MintParams({
                poolAddress: address(pool),
                lowerTick: tick(4545),
                upperTick: tick(5500),
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        quoter = new UniswapV3Quoter();
    }

    // TODO: 测试报价功能 - 买入ETH
    // 提示：
    // 1. 使用Quoter获取用42 USDC能买多少ETH的报价
    // 2. 实际执行交换
    // 3. 验证报价与实际交换结果一致
    function testQuoteBuyETH() public {
        // TODO: 实现测试逻辑
        // 调用quoter.quote获取报价
        // 执行实际交换
        // 比较两者结果
    }

    // TODO: 测试报价功能 - 卖出ETH
    // 提示：
    // 1. 测试反向交换的报价
    // 2. 验证报价准确性
    function testQuoteSellETH() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试跨多个tick的报价
    // 提示：
    // 1. 添加更多流动性范围
    // 2. 测试大额交换的报价
    // 3. 验证复杂情况下的准确性
    function testQuoteMultipleTicks() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试边界情况 - 流动性不足
    // 提示：
    // 1. 尝试报价超过池子流动性的交换
    // 2. 验证返回部分成交的结果
    function testQuoteInsufficientLiquidity() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试报价不影响池子状态
    // 提示：
    // 1. 记录报价前的池子状态
    // 2. 执行多次报价
    // 3. 验证池子状态未改变
    function testQuoteDoesNotChangePoolState() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试价格限制的报价
    // 提示：
    // 1. 设置不同的sqrtPriceLimitX96
    // 2. 验证报价遵守价格限制
    function testQuoteWithPriceLimit() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试零输入的报价
    // 提示：
    // 1. 测试输入0的情况
    // 2. 验证返回0输出
    function testQuoteZeroInput() public {
        // TODO: 实现测试逻辑
    }
}
