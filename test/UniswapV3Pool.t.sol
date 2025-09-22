// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "./UniswapV3Pool.Utils.t.sol";

import "../src/interfaces/IUniswapV3Pool.sol";
import "../src/lib/LiquidityMath.sol";
import "../src/lib/TickMath.sol";
import "../src/UniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3PoolTest is Test, UniswapV3PoolUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;

    bool transferInMintCallback = true;
    bool flashCallbackCalled = false;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH");
        token1 = new ERC20Mintable("USDC", "USDC");
    }

    // TODO: 测试在价格范围内铸造流动性
    // 提示：
    // 1. 创建一个价格范围（如4545-5500），当前价格为5000
    // 2. 准备WETH和USDC代币
    // 3. 调用setupTestCase设置测试环境
    // 4. 验证池子中的代币余额是否正确
    // 预期值参考：
    // - token0: 约0.998995580131581600 ether
    // - token1: 约4999.999999999999999999 ether
    function testMintInRange() public {
        // Step 1: 创建流动性范围数组
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        
        // Step 2: 设置测试参数
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        
        // Step 3: 调用已实现的setupTestCase
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0.998995580131581600 ether,
            4999.999999999999999999 ether
        );
        
        // Step 4: 验证结果
        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );
    }

    // TODO: 测试在价格范围下方铸造流动性
    // 提示：
    // 1. 创建一个完全在当前价格下方的范围（如4000-4996）
    // 2. 在这种情况下，只需要提供token1（USDC）
    // 3. 验证池子中只有token1，没有token0
    function testMintBelowRange() public {
        // Step 1: 创建流动性范围数组
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 4900, 1 ether, 5000 ether, 5000);
        
        // Step 2: 设置测试参数
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        
        // Step 3: 调用已实现的setupTestCase
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0 ether,
            4999.999999999999999999 ether
        );
        
        // Step 4: 验证结果
        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );
    }

    // TODO: 测试在价格范围上方铸造流动性
    // 提示：
    // 1. 创建一个完全在当前价格上方的范围（如5001-6250）
    // 2. 在这种情况下，只需要提供token0（WETH）
    // 3. 验证池子中只有token0，没有token1
    function testMintAboveRange() public {
        // Step 1: 创建流动性范围数组
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(5050, 5550, 1 ether, 5000 ether, 5000);
        
        // Step 2: 设置测试参数
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        
        // Step 3: 调用已实现的setupTestCase
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            1 ether,
            0 ether
        );
        
        // Step 4: 验证结果
        assertEq(
            poolBalance0,
            expectedAmount0,
            "incorrect token0 deposited amount"
        );
        assertEq(
            poolBalance1,
            expectedAmount1,
            "incorrect token1 deposited amount"
        );
    
    }

    // TODO: 测试当回调中不转移代币时的失败情况
    // 提示：
    // 1. 设置transferInMintCallback = false
    // 2. 使用vm.expectRevert预期交易失败
    // 3. 错误信息应该是"InvalidBalances"
    function test_RevertWhen_MintInsufficientBalances() public {
        // Step 1: 创建流动性范围数组
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4545, 5500, 1 ether, 5000 ether, 5000);
        
        // Step 2: 设置测试参数
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 0 ether,
            usdcBalance: 0 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            transferInMintCallback: false,
            transferInSwapCallback: true,
            mintLiqudity: false
        });
        
        setupTestCase(params);
        
        // 期望交易失败
        vm.expectRevert(encodeError("InsufficientInputAmount()"));
        pool.mint(
            address(this),
            liquidity[0].lowerTick,
            liquidity[0].upperTick,
            liquidity[0].amount,
            ""
        );
    }

    // TODO: 测试闪电贷功能
    // 提示：
    // 1. 先添加流动性到池子
    // 2. 调用pool.flash执行闪电贷
    // 3. 在回调中验证借出的金额
    // 4. 确保正确支付手续费
    // 5. 验证最终池子余额增加了手续费
    function testFlash() public {
        // TODO: 实现测试逻辑
    }

    // TODO: 测试收取流动性的功能
    // 提示：
    // 1. 先铸造一个流动性位置
    // 2. 执行一些交换产生手续费
    // 3. 调用pool.collect收取手续费
    // 4. 验证收取的手续费金额
    function testCollectFees() public {
        // TODO: 实现测试逻辑
    }

    // 回调函数实现
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        if (transferInMintCallback) {
            IUniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (IUniswapV3Pool.CallbackData)
            );

            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }
    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        // TODO: 实现交换回调
    // 只需要转移要支付的代币（amount > 0的那个）
    }

    // function uniswapV3FlashCallback(
    //     uint256 amount0,
    //     uint256 amount1,
    //     bytes calldata data
    // ) public {
    //     flashCallbackCalled = true;
        
    //     // TODO: 实现闪电贷回调
    //     // 1. 验证借出的金额
    //     // 2. 计算手续费
    //     // 3. 归还本金+手续费
    // }

    // 基础setupTestCase实现 - 这是测试的基础，必须先完成
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

            bytes memory extra = encodeExtra(
                address(token0),
                address(token1),
                address(this)
            );

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
        // transferInSwapCallback在具体测试中设置
    }
}
