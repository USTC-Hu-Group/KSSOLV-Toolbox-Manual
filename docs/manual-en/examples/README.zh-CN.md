# 中文用户手册配套案例

这些文件对应手册中的计算、结构建模与体数据教程。计算和建模参考运行使用 MATLAB® R2026b、macOS Apple Silicon、CPU、`-nojvm`；独立应用与Online中实际完成的操作另外标明。本仓库随附可公开的输入、脚本与结果数据；编写期间的原始运行日志和内部审校记录已归档，不包含在本仓库中。

## 在应用中打开

- `H2-Online-SCF-050.ks`：本轮Online实际运行、云端保存并下载的氢分子SCF项目，3,544,680字节。Molecule、PBE、default赝势、20 Ha、Nspin=1；7步收敛，总能量−1.1652136532206 Ha，相对密度误差约6.236e−9。它与完整MATLAB®参考项目及此前桌面重算记录分开保留。本轮文件登记只检查容器与数据；重新打开的应用验收另行记录。
- `h2-tutorial.ks`：氢分子、SCF 和 Relaxation 工作流、已完成参考运行的数据与收敛曲线。本版还保留2026-10-20在签名桌面应用中实际重算并保存的SCF结果；7步收敛，总能量约−1.1652136532206 Ha。
- `Si-introduction.ks`：第04章硅导入练习，由最新版桌面GUI实际保存，供检查项目与结构管理。
- `silicon-tutorial.ks`：八原子硅晶胞、SCF 与 DOS 工作流，以及参考运行保存的数值和早期图形条目。跨版本无法恢复旧图形对象时，使用下述重绘脚本。
- `silicon-band-primitive.ks`：二原子标准硅原胞、Energy Band 与 Symmetry 工作流，以及使用匹配原胞倒格坐标计算的能带和DOS数值。当前软件中的两种参考结果视图均可从这些保存数值重绘。
- `h2.cif`：初始氢分子。立方盒 10 Bohr，键长 1.5 Bohr。
- `h2_optimized.cif`：参考运行优化后的氢分子，键长约 0.75729194 Å。
- `silicon.cif`：八原子立方硅晶胞，晶格常数 5.4437023729394527 Å。
- `silicon_primitive.cif`：同一硅晶体的二原子原胞，三条晶格矢量等长、互成 60°，供推荐高对称路径能带教程使用。
- `Si-primitive-BZ-Online-050.pdf`：同一二位点硅原胞在Online中由Symmetry四节点模板实际生成、从结果图工具条导出的三维布里渊区与路径矢量图，无需SCF；1页、14,714字节。云端项目保存后已实际重开，重新打开BZ3D可恢复图形与标签，观察角度回到默认值；本次没有下载该项目的`.ks`。可直接打开本目录随附的PDF查看结果。

## 在当前界面中重绘保存结果

`show_reference_results.m`供已经启动完整MATLAB®工具箱图形界面的用户调用。先在工具箱中打开`silicon-band-primitive.ks`，将MATLAB®当前文件夹设为本手册仓库根目录，再在MATLAB®自身的命令窗口执行：

```matlab
addpath(fullfile(pwd, 'docs', 'manual-zh-CN', 'examples'));
show_reference_results("bands");
show_reference_results("dos");
```

脚本读取当前项目数据集中保存的`bandProcessing`或`DOS`，调用当前工具箱的原生结果绘图任务，在项目的`Results → Plots`中新增图形并打开文档。能带图与DOS图都来自这份二原子硅原胞的数据；打开另一份`silicon-tutorial.ks`再执行`show_reference_results("dos")`，才会绘出八原子常规晶胞的DOS。

这一过程不调用SCF或非自洽电子求解，不改变原始能量数组、路径坐标和能量参照，也不覆盖随书文件；仅整理图形的字号、线宽和重复端点标签。保存图片使用图形工具条；保留新增图形时，将当前项目另存为自己的副本。旧`.ks`中的序列化图形对象在当前版本可能报“对象已删除”；该图形对象与数值记录分开保存，重绘使用的是后者。

该脚本需要完整MATLAB®工具箱及活动项目。使用独立Runtime或在线版生成新结果时，按手册运行相应工作流。

## 建模与体数据示例

- `Si.poscar`：第七章的八位点硅建模输入，边长约 5.46873 Å；与硅计算教程的 `silicon.cif` 不同。
- `Si-vacancy-tutorial.ks`：第七章实际建模后另存的项目，含原来的`silicon`对照结构和`Si`空位模型。后者由`Si.poscar`建立2×2×2超胞，再移去序号1的位点，最终为63个位点；中间的64位点无缺陷超胞未作为单独文件提供。原`Si-introduction.ks`保留不变。
- `CHGCAR.nospin.gz`、`CHGCAR.spin.gz`、`elec.cube.gz`、`datagrid_3d.xsf`：第十章的不同格式与通道示例，保留源文件的物理含义。
- `VOLUME-SOURCES.md`、`PYMATGEN-MIT-LICENSE.txt`：以上四个体数据文件的来源、哈希与随附许可。
- `elec.total.slice-1_1_0.csv`、`elec.total.slice-1_1_0.png`：本轮Online从`elec.cube.gz`的total通道实际导出的(110)切面。CSV为195,163字节，表头为`i,j,k,x_angstrom,y_angstrom,z_angstrom,value`，包含1,568行数据，其中778个有限值、790个面外NaN。坐标以Å表示，value保留通道内部单位；有限最大值约2.399487，不随显示颜色上限0.2截断。PNG为12,963字节、384×768像素的RGBA切面图，适合检查当前配色，不是高分辨率印刷图。
- `benzene*.json`、`pyridine*.json`及第七章列出的乙醇骨架、初始、编辑、整理和优化JSON：芳香分子与乙醇建模的真实中间结构和通用分子模型优化结果。原生JSON保留显式连接与芳香键；完整参数、文件区别和已知格式限制见 `MODELING-CASES.zh-CN.md`。
- `ethanol-angle1095.json`：本轮Online几何编辑后通过原生文件保存导出的乙醇，C2H6O、9个原子、8条显式单键，电荷0、单重态；按1(C)—2(C)—3(O)定义的键角为109.5°。它是结构JSON，用于继续导入、编辑模型。
- `ethanol-angle1095.png`：同一乙醇从原子查看器`Export image → PNG`实际导出的4032×1964 RGBA图像，749,475字节；不是浏览器截图或Hero Shot。本次alpha均为255，画布为不透明背景。
- `ethanol-angle1095-scene.json`：从原子查看器`Export file → Scene JSON`实际下载的atomic-scene 2.0场景，48,932字节，含9个sites/atomInstances和8个bondRelations/bondInstances；其坐标与显式连接逐项匹配上述结构JSON，不能把这个场景文件当成原生Molecule结构JSON导入。
- `Cu-fcc.cif`、`Cu-vacancy.cif`、`Pt-fcc.cif`、`Pt111-slab.cif`：第八章空间群、空位枚举和Pt(111)表面例子的源模式参考结构；不是桌面或Online实机截图的替代。
- `modeling_examples.m`、`verify_modeling_examples.m`：构建与独立重新导入检查；结果分别在 `modeling-examples-results.json`、`modeling-examples-verification.json`。
- `PEO3-PPO4-PEO3.json`、`PE6-PP14-seed91.json`：第八章两种组成明确的高分子初始链，分别含84、164个原子。序列、组成、连接及原生JSON导入已在源模式核对；当前立构选项只改变标记、未改变坐标，详见 `POLYMER-NEB-CASES.zh-CN.md`。
- `neb-exchange/`：两个带固定位点标签的H交换位置的几何练习，含初态、终态及5个IDPP中间构型；没有反应能或能垒结果。
- `polymer_neb_examples.m`、`polymer-neb-examples-results.json`：以上高分子和路径例子的实际构建脚本与定量报告。
- `graphene-layer.json`、`graphene-inserted.json`、`graphene-stacked.json`：同材石墨烯层、平移插入与候选堆叠练习，最终为4位点双层；不是异种材料界面。
- `water-packing.json`、`water10-ethanol10-packed.json`：水分子输入及10水/10乙醇的低密度装填结果。固定种子23，默认密度1 g/cm³失败，保留同样数量与接触要求后以0.1 g/cm³生成。
- `interface_packing_examples.m`、`interface-packing-examples-results.json`、`INTERFACE-PACKING-CASES.zh-CN.md`：插入、堆叠候选、密度和跨周期接触的完整参数、结果与失败记录。
- `oh-fragment.mol`、`Pt111-normal-c.json`、`Pt111-normal-c-OH-outward.json`：O–H参数放置的参考输入与定向结果。该Pt晶胞的c沿真实表面法向；取向原子2、方向`1 1 1`后，O/H距顶位沿法向分别为2/2.96 Å。
- `Pt111-OH-Online-050.json`：Online V0.5.0实际参数放置并应用、以1×1×1单位超胞归胞后导出的结构，含Pt4OH共6个位点。独立JSON核对得到O/H法向高度2.00/2.96 Å、O–H长0.96 Å；与上述向外参考结构在周期边界下等价。不是吸附能或DFT计算结果。
- `Pt111-OH-outward.cif`：上述向外吸附结构的CIF副本，供直接查看几何或准备后续计算。已通过源模式StructureIO读回核对Pt4OH、O/H高度与O–H距离；CIF不保留分子显式拓扑，尚无GUI视图验收声明。
- `Pt111-OH-c-offset.json`、`Pt111-normal-c-OH-ontop.json`、`Pt111-OH-candidate-1.json`：原斜胞的c偏移诊断、法向胞的未定向放置和几何评分候选；它们各有用途，不能把第一份的offset2 Å当作法向高度2 Å。
- `hBN-layer.json`、`graphene-hBN-stacked.json`：采用编写时软件示例中的理想片层参数的真正异材匹配；C2BN、4个位点、面内应变1.6%、层距3.35 Å。
- `ADSORPTION-BN-CASES.zh-CN.md`：以上案例的参数、文件区别及单键JSON形状范围；脚本为 `adsorption_bn_examples.m`、`verify_adsorption_bn_examples.m`、`orient_oh_example.m`，定量报告分别随脚本命名保存。

通过应用的“打开”命令选择 `.ks` 文件。首次查看节点时，选中节点，再使用“工作流 → 配置节点”或节点上的齿轮，向下滚动至专用选项。项目中已有图形来自保留日志的实际计算。`h2-tutorial.ks`的SCF流程已在本轮桌面应用中实际运行并保存，可再次执行；其他教程或节点的状态以项目中的实际记录为准，不把它们一概视为待运行。

独立应用的实机复算涵盖H2 SCF，结果保留在`h2-tutorial.ks`中；几何优化资料仍来自完整MATLAB®的参考运行，参数和结果见`h2_scf_and_relax.m`及其配套JSON。原始过程日志已归档。

## 本轮Online文件的验证范围

Online项目、切面、乙醇查看器与Pt(111)吸附结构的公开文件及规格列在上文，可与本目录中的实际文件对照。编写期间的逐项文件登记、哈希审计及过程记录已归档，不随本仓库提供。项目文件通过只读MAT/HDF5容器检查，乙醇JSON通过结构字段、坐标和连接对照，PNG通过解码及实际查看；没有在文件登记检查中加载项目对象、重新导入模型或复跑SCF。结构JSON原样保留云端源文件路径，场景JSON原样保留请求标识；上述Online导出文件的登记扫描未发现常见凭据、认证查询串或个人主目录路径；这一结论不涵盖其他历史参考JSON中的环境来源字段。

<a id="在-matlab-中重复计算"></a>

## 在 MATLAB® 中重复计算

本手册仓库与软件仓库分别存放。先设置软件源码根目录，其中应包含`KSSOLV_Toolbox.m`及`+kssolv/`。从本手册仓库根目录在终端执行，例如：

```sh
export KSSOLV_TOOLBOX_ROOT=/path/to/KSSOLV-Toolbox
matlab -nojvm -nodesktop -batch "run('docs/manual-zh-CN/examples/h2_scf_and_relax.m')"
```

将示例路径换成实际软件位置；若`matlab`不在命令搜索路径中，可使用MATLAB®可执行文件的完整路径。未设置该环境变量时，引导程序尝试通过`which KSSOLV_Toolbox`定位已加入MATLAB®路径的软件。仅安装独立应用程序不等于具备可执行这些脚本的完整MATLAB®源码环境。

也可先以`-nojvm`启动完整MATLAB®，在命令窗口配置后逐项运行：

```matlab
setenv('KSSOLV_TOOLBOX_ROOT', '/path/to/KSSOLV-Toolbox');
```

当前工作目录应为本手册仓库根目录：

```matlab
run('docs/manual-zh-CN/examples/h2_scf_and_relax.m')
run('docs/manual-zh-CN/examples/silicon_example.m')
run('docs/manual-zh-CN/examples/silicon_primitive_example.m')
run('docs/manual-zh-CN/examples/modeling_examples.m')
run('docs/manual-zh-CN/examples/verify_modeling_examples.m')
run('docs/manual-zh-CN/examples/polymer_neb_examples.m')
run('docs/manual-zh-CN/examples/interface_packing_examples.m')
run('docs/manual-zh-CN/examples/adsorption_bn_examples.m')
run('docs/manual-zh-CN/examples/verify_adsorption_bn_examples.m')
run('docs/manual-zh-CN/examples/orient_oh_example.m')
run('docs/manual-zh-CN/examples/export_oh_cif.m')
```

也可在上述终端命令中替换脚本名，使用 MATLAB® 的 `-nojvm -batch` 方式逐项执行。氢分子的 fminunc 优化在 MATLAB® 环境中需要 Optimization Toolbox。

所有新生成的结构、JSON/MAT报告、日志和诊断文件集中写入本手册仓库的`output/reference-runs/`，随书`examples/`参考文件保持不变。`verify_*.m`读取随书参考文件，将新的核对报告写入输出目录。H2 的 MAT 中同时保存 `initialGeometry` 与 `optimizedGeometry` 两个普通结构体，其 `supercell` 与 `xyzlist` 均以 Bohr 为单位。硅脚本还输出 DOS CSV：第一列为相对费米能的能量（eV），第二列为总态密度。

H2 采用 PBE、default 赝势、20 Ha、10 Bohr 盒，先做 SCF，再以 fminunc、1e-4 阈值、100 最大步数优化。两种硅晶胞均采用 PBE、default、20 Ha、2×2×2 SCF 网格和额外 4 条能带。八原子例演示 DOS（4×4×4 网格、−10 至 10 eV、步长 0.05 eV）；二原子例演示能带（每段 8 点）。两种晶胞的相同整数网格并不代表相同倒空间采样密度，不直接比较它们的每原子总能量。这些小规模设置用于学习完整流程。

推荐高对称路径的分数坐标属于标准原胞；能带教程因此明确使用匹配的二原子原胞。八原子示例项目只保留 SCF 和 DOS，不沿用未转换的原胞路径。相应晶格、采样点和能带结果可对照`silicon_primitive.cif`、`silicon_primitive_example.m`及配套数据；编写阶段的内部审计不随本仓库提供。


## 纳米结构补充案例

`NANO-CASES.zh-CN.md`说明新增的石墨烯带/管与铜线/点/孔。`nano-graphene-60.json`是从既有石墨烯用行列式1换基得到的60度原胞；本组带/管使用该输入。实际结果为24C扶手椅带、32C的(4,0)管、24Cu纳米线、13Cu有限团簇，以及32Cu宿主去13留19的球形孔。各结果提供JSON/CIF；JSON保留低维周期，CIF读回当前恢复三向周期。

按上述软件路径准备，在以`-nojvm`启动的完整MATLAB®环境运行`nano_examples.m`重新生成，或运行`verify_nano_examples.m`只核对八对保存文件。数值与输入对照见`nano-examples-results.json`，独立读取见`nano-examples-verification.json`。原120度输入的不合适管几何仅保留在研究诊断文件，不作为本节示例输出；没有GUI或能量计算验收声明。
