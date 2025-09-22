# UniswapV3 测试练习框架

这是一个为了提升您的测试编写能力而创建的练习框架。每个测试文件都包含了基础设置和结构，但核心测试逻辑需要您自己实现。

## 文件结构

- `UniswapV3Pool.t.sol` - Pool合约基础功能测试
- `UniswapV3Pool.Swaps.t.sol` - Pool合约交换功能测试  
- `UniswapV3Manager.t.sol` - Manager合约测试
- `UniswapV3Quoter.t.sol` - Quoter合约测试
- `TestUtils.sol` - 测试工具函数（已完整提供）
- `ERC20Mintable.sol` - 测试用代币合约（已完整提供）
- `UniswapV3Pool.Utils.t.sol` - Pool测试工具函数

## 练习目标

1. **理解测试结构** - 学习如何组织测试代码
2. **编写断言** - 学习如何验证合约状态
3. **处理边界情况** - 学习如何测试边界条件
4. **模拟失败场景** - 学习如何测试错误处理

## 如何使用

1. 阅读每个文件中的注释，理解需要实现的功能
2. 参考老师的示例代码，但尝试自己先思考实现方案
3. 运行测试验证您的实现：`forge test`
4. 对比您的实现与老师的实现，学习不同的测试策略

## 测试编写提示

1. **Setup阶段** - 初始化测试环境
2. **Action阶段** - 执行待测试的操作
3. **Assert阶段** - 验证结果是否符合预期

## 需要重点练习的测试技能

- 使用 `assertEq` 验证数值相等
- 使用 `assertTrue/assertFalse` 验证布尔条件
- 使用 `vm.expectRevert` 测试失败场景
- 使用 `vm.prank` 模拟不同用户
- 理解回调机制的测试方法
