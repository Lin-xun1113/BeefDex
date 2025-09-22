# UniswapV3 测试练习指南

## ⚠️ 重要提示

**基础函数已实现！** `setupTestCase` 函数已经在每个测试文件中提供了基础实现，您可以直接开始练习测试用例。

## 练习顺序建议

建议按照以下顺序完成测试练习，从简单到复杂：

### 第一阶段：基础测试 (UniswapV3Pool.t.sol)
- [ ] `testMintInRange` - 理解流动性添加的基本流程
- [ ] `testMintBelowRange` - 理解单边流动性
- [ ] `testMintAboveRange` - 理解单边流动性
- [ ] `testFailMintInsufficientBalances` - 学习错误处理测试

### 第二阶段：交换测试 (UniswapV3Pool.Swaps.t.sol)
- [ ] `testBuyETHOnePriceRange` - 基础交换测试
- [ ] `testSellETHOnePriceRange` - 反向交换测试
- [ ] `testBuyETHTwoLiquidityRanges` - 多流动性范围
- [ ] `testBuyETHLiquidityGap` - 处理流动性间隙
- [ ] `testInvalidPriceLimit` - 边界条件测试

### 第三阶段：Manager测试 (UniswapV3Manager.t.sol)
- [ ] `testMintInRange` - 通过Manager添加流动性
- [ ] `testMintRangeSlippageProtectionSuccess` - 滑点保护成功
- [ ] `testMintRangeSlippageProtectionFail` - 滑点保护失败
- [ ] `testSwapBuyETH` - 通过Manager交换

### 第四阶段：高级功能 (UniswapV3Quoter.t.sol & UniswapV3Pool.t.sol)
- [ ] `testQuoteBuyETH` - 报价功能
- [ ] `testFlash` - 闪电贷测试
- [ ] `testCollectFees` - 手续费收取

## 测试编写技巧

### 1. 断言的使用
```solidity
// 数值相等
assertEq(actual, expected, "error message");

// 布尔断言
assertTrue(condition, "should be true");
assertFalse(condition, "should be false");

// 近似相等（用于浮点数）
assertApproxEqAbs(a, b, maxDelta);
```

### 2. 预期失败
```solidity
// 预期revert
vm.expectRevert("error message");
// 或
vm.expectRevert(abi.encodeWithSignature("ErrorName(uint256)", value));
```

### 3. 模拟用户
```solidity
vm.prank(userAddress); // 下一次调用来自userAddress
vm.startPrank(userAddress); // 开始模拟
// ... 多个调用
vm.stopPrank(); // 停止模拟
```

### 4. 测试结构
```solidity
function testSomething() public {
    // Arrange - 设置初始状态
    
    // Act - 执行操作
    
    // Assert - 验证结果
}
```

## 重要概念理解

### 流动性相关
1. **价格范围内的流动性**：需要提供两种代币
2. **价格范围外的流动性**：只需要提供一种代币
3. **流动性计算**：使用 `LiquidityMath.getLiquidityForAmounts`

### 交换相关
1. **zeroForOne**：true表示用token0换token1，false表示相反
2. **价格影响**：交换量越大，价格影响越大
3. **滑点保护**：设置最小输出量或价格限制

### 回调机制
1. **MintCallback**：Pool要求Manager转入代币
2. **SwapCallback**：Pool要求支付交换的代币
3. **FlashCallback**：闪电贷归还本金和手续费

## 调试技巧

1. 使用 `console.log` 输出中间值
```solidity
import "forge-std/console.sol";
console.log("value:", value);
```

2. 运行特定测试
```bash
forge test --match-test testMintInRange -vvv
```

3. 查看详细错误信息
```bash
forge test -vvvv
```

## 完成标准

每个测试应该：
1. ✅ 正确设置测试环境
2. ✅ 执行目标操作
3. ✅ 验证所有相关状态变化
4. ✅ 处理边界情况
5. ✅ 包含清晰的注释说明测试目的

## 参考资源

- 老师的完整实现：`/home/linxun/Coding/Defi/BeefDex/uniswapv3-code/test/`
- Forge测试文档：https://book.getfoundry.sh/forge/tests
- UniswapV3文档：https://docs.uniswap.org/contracts/v3/overview

加油！通过实践您会快速掌握测试编写技能！💪
