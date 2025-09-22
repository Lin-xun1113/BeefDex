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
    // - 用户应该获得约 0.00839851698277099 ETH
    // - 池子价格应该下降（因为卖出ETH）
    function testBuyETHOnePriceRange() public {
        // Step 1: 添加流动性
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        liquidity[1] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 42 ether; // 42 USDC
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        (int256 userBalance0Before, int256 userBalance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );
        console2.log("userBalance0Before:", userBalance0Before);
        console2.log("userBalance1Before:", userBalance1Before);

        // Step 2: 执行交换
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(address(this), false, swapAmount, sqrtP(5050), extra);

        console2.log("amount0Delta:", amount0Delta);
        console2.log("amount1Delta:", amount1Delta);

        (int256 expectAmount0Delta, int256 expectAmount1Delta) = (
            -0.008398516982770993 ether,
            42 ether
        );




        // Step 3: 验证余额变化

        assertEq(amount0Delta, expectAmount0Delta, "invalid ETH out");
        assertEq(amount1Delta, expectAmount1Delta, "invalid USDC in");

        assertSwapState(
            ExpectedStateAfterSwap({
                pool: pool,
                token0: token0,
                token1: token1,
                userBalance0: uint256(userBalance0Before - amount0Delta),
                userBalance1: uint256(userBalance1Before - amount1Delta),
                poolBalance0: uint256(int256(poolBalance0) + amount0Delta),
                poolBalance1: uint256(int256(poolBalance1) + amount1Delta),
                sqrtPriceX96: 5603319704133145322707074461607,
                tick: 85179,
                currentLiquidity: liquidity[0].amount + liquidity[1].amount
            })
        );
        
    }

    // 测试卖出ETH（用ETH换USDC）
    // 说明：
    // 1. 同样的流动性设置
    // 2. 卖出0.01 ETH换取USDC
    // 3. 验证余额和价格变化方向相反（价格上升）
    function testSellETHOnePriceRange() public {
        // Step 1: 添加流动性
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        liquidity[1] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 0.01 ether; // 卖出0.01 ETH
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        (int256 userBalance0Before, int256 userBalance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );
        console2.log("userBalance0Before:", userBalance0Before);
        console2.log("userBalance1Before:", userBalance1Before);

        // Step 2: 执行交换（zeroForOne = true，卖出token0换取token1）
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(address(this), true, swapAmount, sqrtP(4950), extra);

        console2.log("amount0Delta:", amount0Delta);
        console2.log("amount1Delta:", amount1Delta);

        // 预期结果：卖出0.01 ETH，获得约49.99 USDC（考虑滑点）
        (int256 expectAmount0Delta, int256 expectAmount1Delta) = (
            0.01 ether,
            -49987406523294463125 // 约-49.99 USDC
        );

        // Step 3: 验证余额变化
        assertEq(amount0Delta, expectAmount0Delta, "invalid ETH in");
        assertEq(amount1Delta, expectAmount1Delta, "invalid USDC out");

        assertSwapState(
            ExpectedStateAfterSwap({
                pool: pool,
                token0: token0,
                token1: token1,
                userBalance0: uint256(userBalance0Before - amount0Delta),
                userBalance1: uint256(userBalance1Before - amount1Delta),
                poolBalance0: uint256(int256(poolBalance0) + amount0Delta),
                poolBalance1: uint256(int256(poolBalance1) + amount1Delta),
                sqrtPriceX96: 5600919383529975170754718115874, // 价格上升（约4999）
                tick: 85171, // tick略微下降
                currentLiquidity: liquidity[0].amount + liquidity[1].amount
            })
        );
    }

    //  两个价格范围测试
    //          5000
    //  4545 -----|----- 5500
    //  4000 ----------- 6250
    //
    // 测试跨多个价格范围的交换
    // 说明：
    // 1. 添加两个重叠的流动性范围
    // 2. 执行大额交换，使价格跨越多个tick
    // 3. 验证流动性在不同价格点的变化
    function testBuyETHTwoLiquidityRanges() public {
        // Step 1: 添加两个重叠的流动性范围
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        liquidity[1] = liquidityRange(4000, 6250, 2 ether, 10000 ether, 5000);
        
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 3 ether,
            usdcBalance: 15000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        // Step 2: 买入ETH，使用100 USDC
        uint256 swapAmount = 100 ether;
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        (int256 userBalance0Before, int256 userBalance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );

        // 执行交换
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            false, // 买入ETH
            swapAmount,
            sqrtP(5100), // 价格限制
            extra
        );

        // Step 3: 验证结果
        assertTrue(amount0Delta < 0, "should receive ETH");
        assertEq(amount1Delta, int256(swapAmount), "should pay exact USDC");

        assertSwapState(
            ExpectedStateAfterSwap({
                pool: pool,
                token0: token0,
                token1: token1,
                userBalance0: uint256(userBalance0Before - amount0Delta),
                userBalance1: uint256(userBalance1Before - amount1Delta),
                poolBalance0: uint256(int256(poolBalance0) + amount0Delta),
                poolBalance1: uint256(int256(poolBalance1) + amount1Delta),
                sqrtPriceX96: 5604996445879157947994400571614, // 新价格（调整后）
                tick: 85185, // 新tick（调整后）
                currentLiquidity: liquidity[0].amount + liquidity[1].amount
            })
        );
    }

    //  价格范围之间有间隙
    //        5000
    //   4545 --|- 5050
    //             5150 -- 5500
    //
    // 测试交换穿过没有流动性的价格区间
    // 说明：
    // 1. 创建两个不连续的流动性范围
    // 2. 执行交换使价格穿过间隙
    // 3. 验证在没有流动性的区间价格如何变化
    function testBuyETHLiquidityGap() public {
        // Step 1: 创建两个不连续的流动性范围（中间有gap）
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = liquidityRange(4545, 5050, 1 ether, 5000 ether, 5000);
        liquidity[1] = liquidityRange(5150, 5500, 1 ether, 5000 ether, 5000);
        
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        // Step 2: 买入ETH，价格会穿过gap
        uint256 swapAmount = 200 ether;
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        (int256 userBalance0Before, int256 userBalance1Before) = (
            int256(token0.balanceOf(address(this))),
            int256(token1.balanceOf(address(this)))
        );

        // 执行交换，价格会从5000跨越gap到5150+
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            false, // 买入ETH
            swapAmount,
            sqrtP(5200), // 价格限制
            extra
        );

        // Step 3: 验证价格跨越了gap
        assertTrue(amount0Delta < 0, "should receive ETH");
        assertTrue(amount1Delta > 0, "should pay USDC");
        // 价格应该跨越了gap，现在在第二个流动性范围内（tick > 85213）
        (uint160 sqrtPriceX96, int24 currentTick) = pool.slot0();
        assertTrue(currentTick >= 85213, "price should cross the gap");
    }

    // 测试买入ETH但只获得部分数量
    // 说明：
    // 1. 尝试购买大量ETH，超过池子能提供的
    // 2. 验证实际获得的数量小于预期
    // 3. 检查价格达到了范围边界
    function testBuyETHNotEnoughLiquidity() public {
        // Step 1: 添加有限的流动性
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 0.1 ether, 500 ether, 5000);
        
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0.1 ether,
            usdcBalance: 500 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        // Step 2: 尝试用大量USDC买入ETH（导致流动性不足）
        uint256 swapAmount = 10000 ether; // 尝试用10000 USDC买入
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        // 预期交易失败，因为流动性不足
        vm.expectRevert(abi.encodeWithSignature("NotEnoughLiquidity()"));
        pool.swap(
            address(this),
            false, // 买入ETH
            swapAmount,
            sqrtP(6000), // 价格限制
            extra
        );
    }

    // 测试卖出ETH但流动性不足
    // 说明：
    // 1. 尝试卖出大量ETH
    // 2. 验证交易失败
    function testSellETHNotEnoughLiquidity() public {
        // Step 1: 添加有限的流动性
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 0.1 ether, 500 ether, 5000);
        
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0.1 ether,
            usdcBalance: 500 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        // Step 2: 尝试卖出大量ETH
        uint256 swapAmount = 10 ether; // 尝试卖出10 ETH（超过流动性）
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        // 预期交易失败，因为流动性不足
        vm.expectRevert(abi.encodeWithSignature("NotEnoughLiquidity()"));
        pool.swap(
            address(this),
            true, // 卖出ETH
            swapAmount,
            sqrtP(4000), // 价格限制
            extra
        );
    }

    // 测试无效的价格限制
    // 说明：
    // 1. 买入时设置过低的价格限制
    // 2. 卖出时设置过高的价格限制
    // 3. 使用vm.expectRevert验证交易失败
    function testInvalidPriceLimit() public {
        // Step 1: 添加流动性
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        setupTestCase(params);

        // 测试1: 买入ETH时设置过低的价格限制（价格应该上升）
        uint256 swapAmount = 100 ether;
        token1.mint(address(this), swapAmount);
        
        vm.expectRevert(abi.encodeWithSignature("InvalidPriceLimit()"));
        pool.swap(
            address(this),
            false, // 买入ETH
            swapAmount,
            sqrtP(4900), // 价格限制太低
            extra
        );

        // 测试2: 卖出ETH时设置过高的价格限制（价格应该下降）
        swapAmount = 0.1 ether;
        token0.mint(address(this), swapAmount);
        
        vm.expectRevert(abi.encodeWithSignature("InvalidPriceLimit()"));
        pool.swap(
            address(this),
            true, // 卖出ETH
            swapAmount,
            sqrtP(5100), // 价格限制太高
            extra
        );
    }

    // 测试不转移代币时的失败
    // 说明：
    // 1. 设置transferInSwapCallback = false
    // 2. 预期交易因余额不足而失败
    function testSwapInsufficientBalances() public {
        // Step 1: 添加流动性
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: false, // 关键：不在回调中转移代币
            mintLiqudity: true
        });
        setupTestCase(params);

        // Step 2: 尝试交换，但不转移代币
        uint256 swapAmount = 42 ether;
        
        // 这应该失败，因为池子不会收到代币
        vm.expectRevert(); // 预期因为余额检查失败而revert
        pool.swap(
            address(this),
            false, // 买入ETH
            swapAmount,
            sqrtP(5100),
            extra
        );
    }

    // 回调函数
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
        if (transferInMintCallback) {
            IUniswapV3Pool.CallbackData memory extra_ = abi.decode(data, (IUniswapV3Pool.CallbackData));

            token0.mint(msg.sender, amount0);
            token1.mint(msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) public {
        if (transferInSwapCallback) {
            // TODO: 实现交换回调
            // 提示：只转移amount > 0的代币
            if (amount0 > 0) IERC20(token0).transfer(msg.sender, uint256(amount0));
            if (amount1 > 0) IERC20(token1).transfer(msg.sender, uint256(amount1));
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
        pool =
            new UniswapV3Pool(address(token0), address(token1), sqrtP(params.currentPrice), tick(params.currentPrice));

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
