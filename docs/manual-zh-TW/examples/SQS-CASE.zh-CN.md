# 四位点铜镍 SQS 教学例

本例实际调用配套KSSOLV Toolbox中的 `CommandExecutor.execute(..., 'generate_sqs_model', ...)`。验证环境为 MATLAB R2026b（26.2.0.3386108）、macOS arm64，使用 `-nojvm`，记录 JVM=false。未运行 GUI、Online、DFT 或新的本地编译。

## 文件与操作

| 文件 | 用途 |
|---|---|
| `sqs-cu-ni-input.json` / `.cif` | 四个fcc位点，各Cu0.5/Ni0.5；a=3.61 Å仅作教学初值。 |
| `sqs-cu-ni-ordered.json` / `.cif` | 实际有序输出：4位点Cu2Ni2，每个位点单一元素、占位1。 |
| `sqs_example.m` | 生成输入、从JSON回读、调用SQS，再回读输入与输出的JSON/CIF检查。 |
| `sqs-example-results.json` | 参数、计时、组成、占位、距离、元数据与文件回读结果。 |
| `sqs-independent-verification.json` | 独立Python标准库核查文件字节中的组成、CIF标签、周期距离及六种排列的目标值；不重跑生产命令。 |

在工具箱中导入输入JSON，激活晶体文档，从“缺陷与合金”打开“生成 SQS 模型”。SQS超胞倍率填 `1`，搜索时限填 `1` 秒。预览、应用后检查4个位点、Cu2Ni2和最近周期距离约2.552655 Å，再保存项目并导出原生JSON/CIF。Online需先上传输入，输出保存后再下载。

原生JSON的 `properties.sqs` 应包含本次搜索记录；当前GUI没有独立显示SQS目标值的结果窗。CIF保存晶格与占位，不保存这组搜索元数据。输入CIF用八行表示四个混合位点，每坐标两行、Cu与Ni各0.5，不应把八行当成八个独立原子。

## 本次真实结果

- 参数：`scaling=1`、`searchTime=1`；没有扩大四位点晶胞。
- 模式：`exact-enumeration`；组成排列数 `configuration_count=6`。
- 有序输出：Cu2Ni2，4个位点、每点一种元素/占位1，晶格和四个分数位置保持。
- 体积：47.045881 Å³；最近周期距离：2.5526554800834367 Å。
- 目标函数：0.16666666666666669。四个位点共有六对不同位点，一对Cu-Cu、一对Ni-Ni；同种配对率各1/6，与随机独立占位的1/4比较，两项绝对偏差之和为1/6。它不是能量。
- 命令实际耗时：4.4058517083333335秒。小空间精确枚举分支不以1秒作为全部流程的严格截止；该计时还包含结构等价比较等。
- 四份输入/输出JSON/CIF均由真实 `StructureIO` 回读，组成、逐点占位、位点数、晶格和六对距离检查通过。JSON保留输出SQS元数据，CIF不保留。
- 独立文件检查列举全部六种Cu2Ni2排列，其目标值都为1/6；不是声称这一个很小的晶胞已经完整代表宏观随机合金。

## 无JVM重现

先按[案例运行说明](README.zh-CN.md#在-matlab-中重复计算)设置`KSSOLV_TOOLBOX_ROOT`，再从本手册仓库根目录运行：

```sh
matlab -nojvm -nodesktop -batch "run('docs/manual-zh-CN/examples/sqs_example.m')"
```

脚本把新结构、定量结果和日志写入`output/reference-runs/`，不覆盖随书参考文件。公开参数与结果见`sqs-example-results.json`，独立文件检查见`sqs-independent-verification.json`。原始执行日志与编写期间的排错记录已归档，不随本仓库提供；重新运行时会生成新的`sqs-example.log`。

导入混合占位时，`StructureIO`同时为KSSOLV计算对象准备单一元素表示，会给出分数占位不被Atom直接支持的警告。建模侧 `MatgenlabObject` 仍保留真实Cu0.5/Ni0.5，脚本对它逐位点断言后才调用SQS。进行电子结构计算应使用有序结果，不能把计算对象的临时映射当作完成SQS。
