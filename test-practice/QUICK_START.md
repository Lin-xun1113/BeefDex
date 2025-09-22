# 快速上手指南

## 🚀 如何开始练习

### 1. 环境检查
```bash
cd /home/linxun/Coding/Defi/BeefDex/Contract
forge test # 确保环境正常
```

### 2. 重要说明
- ✅ **setupTestCase 已实现** - 每个测试文件都有基础的 setupTestCase 函数
- ✅ **工具函数已提供** - TestUtils.sol 包含所有辅助函数
- ✅ **ERC20Mintable 已实现** - 测试代币合约已完整提供
- ✅ **基础框架已搭建** - setUp 和回调函数框架已准备好

### 3. 第一个测试示例

以 `testMintInRange` 为例，您需要实现：

```solidity
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
    
    // Step 4: 验证结果
    assertEq(
        poolBalance0,
        0.998995580131581600 ether,
        "incorrect token0 deposited amount"
    );
    assertEq(
        poolBalance1,
        4999.999999999999999999 ether,
        "incorrect token1 deposited amount"
    );
}
```

### 4. 回调函数实现提示

对于 `uniswapV3MintCallback`：
```solidity
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
        
        // 铸造并转移代币到池子
        token0.mint(msg.sender, amount0);
        token1.mint(msg.sender, amount1);
    }
}
```

### 5. 测试运行命令

```bash
# 运行单个测试
forge test --match-test testMintInRange -vvv

# 运行某个文件的所有测试
forge test --match-contract UniswapV3PoolTest -vvv

# 调试模式（显示详细信息）
forge test --match-test testMintInRange -vvvv
```

### 6. 常见问题

**Q: setupTestCase 在哪里？**
A: 已经在每个测试文件底部实现了，直接使用即可。

**Q: 为什么测试失败？**
A: 
1. 检查回调函数是否实现
2. 验证断言的预期值是否正确
3. 使用 -vvvv 查看详细错误信息

**Q: LiquidityRange 是什么？**
A: 这是在 UniswapV3Pool.Utils.t.sol 中定义的结构体，用于描述流动性范围。

### 7. 学习路径

1. **先完成回调函数** - 这是基础，很多测试都需要
2. **从简单测试开始** - testMintInRange 是最基础的
3. **理解每个断言** - 知道为什么要验证这些值
4. **对比老师代码** - 完成后对比学习不同实现方式

### 8. 调试技巧

```solidity
// 添加日志输出
import "forge-std/console.sol";

console.log("poolBalance0:", poolBalance0);
console.log("poolBalance1:", poolBalance1);
```

---

现在您可以开始练习了！记住，重要的不是完成速度，而是理解每个测试在做什么，为什么要这样测试。加油！💪
