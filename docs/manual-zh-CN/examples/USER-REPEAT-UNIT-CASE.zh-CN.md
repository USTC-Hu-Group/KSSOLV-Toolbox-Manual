# 自定义重复单元与二聚体

这一组文件对应“建模工具详解”中“保存自定义重复单元”。输入是乙烷的初始几何，用两个碳定义连接骨架，再建立两个重复单元的链；不把这一几何操作当作乙烷聚合反应。

## 图形界面练习

1. 导入`user-repeat-ethane-input.json`。原子1、2为C，3至8为H，合计8原子、7条单键。
2. 从分子建模→软物质→聚合物建模打开“保存用户重复单元”。名称`MANUAL_CC`，头1，尾2，离去原子`3 4 5 6 7 8`。这一步保存库条目，来源乙烷仍有8个原子。
3. 打开“构建均聚物”，重复单元`MANUAL_CC`，重复数2，链数1，种子7，伸展构象，首尾端基none，原子上限1000，其余保留默认。
4. 预览并应用，核对C4H10、14个原子、13条单键、一条完整链。运行分子诊断，检查价态和短接触。
5. 保存项目并导出结构。`user-repeat-CC-dimer.json`是脚本生成的对照结果。

图形操作依据当前参数入口编写，本组没有新增GUI实操或截图验收。图形界面保存时会写入当前用户的重复单元库；下面的脚本只写`output/reference-runs/`中的独立教学库，两者不要混淆。

## 在完整MATLAB中重现

先按[案例运行说明](README.zh-CN.md#在-matlab-中重复计算)设置`KSSOLV_TOOLBOX_ROOT`，再以`-nojvm`启动MATLAB，从本手册仓库根目录运行：

```matlab
run('docs/manual-zh-CN/examples/user_repeat_unit_example.m')
run('docs/manual-zh-CN/examples/verify_user_repeat_unit_example.m')
```

所有新生成文件保存在本手册仓库的`output/reference-runs/`，随书参考文件保持不变。

引导程序根据环境变量或MATLAB入口定位配套软件，并检查关键类确实来自所选软件目录；本手册仓库不随附KSSOLV核心源码。生成脚本把专用`MANUAL_CC`教学条目写到`output/reference-runs/`，不读写个人重复单元库。独立校验脚本只读随书输入、结果和教学库，将核对报告写到输出目录，不重新构建。

随书参考文件与重新生成的同名输出如下；新输出均在`output/reference-runs/`中：

| 文件 | 用途 |
| --- | --- |
| `user-repeat-ethane-input.json` | 8原子来源分子，保留原始序号与7条单键。 |
| `user-repeat-unit-library.json` | 独立教学库；原始条目保存头尾及离去原子，实际连接骨架只有两个C。 |
| `user-repeat-CC-dimer.json` | 二聚体初始几何，C4H10，14原子、13条单键。 |
| `user-repeat-unit-results.json` | 构建参数、坐标、键表与诊断。 |
| `user-repeat-unit-verification.json` | 独立重新导入的组成、连通性、价态和接触检查。 |
| `user-repeat-unit-example.log` | 重新运行生成的过程日志；原始日志已归档。 |

本次MATLAB R2026b/maca64无JVM运行、生成及独立回读均成功退出；诊断没有价态错误、短接触或异常键。模型是未弛豫的教学初始构型，没有执行DFT、计算聚合能或平衡构象搜索。
