# KSSOLV Toolbox 中文用户手册

本手册面向KSSOLV Toolbox **V0.5.0** 版本，适用于独立应用程序、MATLAB®工具箱和KSSOLV Toolbox Online三种使用方式，介绍运行准备、项目管理、结构建模、电子结构计算和结果查看。计算和建模示例同时提供输入文件、脚本及参考结果。

实机操作、源模式参考计算和原理示意图在正文中分别说明。参数窗口、预览、应用、保存和重新打开按实际完成范围记录；截图不代表其中所有选项都已逐项测试。软件安装包与手册版本分别识别，所需平台与MATLAB® Runtime条件以配套软件发行说明为准。

## 交付内容

- **PDF手册**：适合阅读、搜索和打印，包含目录、交叉引用与主题索引。
- **LaTeX源码包**：包含正文、样式、实际使用的可见截图裁片、矢量结果图及构建文件，可在自己的TeX环境中修改和重编。
- **示例文件包**：包含结构、工作流／项目、数值数据和示例脚本；用途与运行方法见`examples/README.zh-CN.md`。

发行批次的文件名与SHA256以同批交付清单为准。源包与案例包保留相同的示例文件；只需阅读时使用PDF即可，不必安装TeX。原始浏览器全屏截图、账号／会话区域和内部审校档案不随公开源码分发。

## 重建PDF

本仓库独立维护手册，不包含KSSOLV Toolbox软件源码。主文件为`docs/manual-zh/main.tex`，样式为同目录的`manual-style.sty`。在本仓库根目录运行：

```sh
python3 -m pip install -r requirements.txt
python3 build.py
```

也可进入`docs/manual-zh/`运行`python3 build.py`。需要Python 3及TeX Live 2026，或具备相同宏包和字体的兼容发行版：

- 工具：XeLaTeX、latexmk、MakeIndex、kpsewhich。
- 宏包：ctex、fontspec、TikZ、tcolorbox、xurl、makeidx、idxlayout等。
- 字体：Fandol中文字体、TeX Gyre Pagella／Heros、Latin Modern Mono和AMS Computer Modern，由TeX发行版提供。
- 字符映射：TeX Live的adobemapping包提供Adobe-GB1-UCS2，许可见`THIRD-PARTY-NOTICES.md`。

`.latexmkrc`和`manual-index.ist`用于生成索引字母分组，需与`main.tex`保留在同一目录。构建临时文件进入`build/`，可分发PDF输出到本仓库根目录的`output/pdf/KSSOLV_Toolbox_User_Manual_zh-CN.pdf`。工具链无需Java／JVM，也不依赖本机商业中文字体。

`build.py`检查编译错误、缺字、横向溢出和未定义引用，并为需要的中文CID字体及扩展数学字符嵌入Unicode映射，以便不同阅读器显示、搜索和复制中文。LaTeX编辑器可直接预览`main.tex`；生成交付PDF时使用上述脚本。

## 使用随书案例

`examples/`中既有可直接导入的结构和`.ks`项目，也有完整MATLAB®参考脚本与JSON结果。先按案例说明选择文件，再按手册步骤操作。带有数值结果的项目、只有结构的项目和场景JSON用途不同，不宜按扩展名相似而互换。

运行MATLAB®脚本需要另行准备配套KSSOLV Toolbox源码或可由MATLAB®找到的工具箱环境；设置`KSSOLV_TOOLBOX_ROOT`指向软件源码根目录，或让`which KSSOLV_Toolbox`能够找到入口。具体准备与命令见[案例说明](examples/README.zh-CN.md#在-matlab-中重复计算)，无图形脚本均使用`-nojvm`。下载项目不需要为阅读手册额外安装MATLAB®。参考数值用于检查量纲、趋势和收敛，随机初值可能使末位有所不同；各例采用的参数与实际结果以随附说明为准。

体数据来源和许可见`examples/VOLUME-SOURCES.md`及`examples/PYMATGEN-MIT-LICENSE.txt`。案例文件的SHA256由同批次清单记录。

## 编辑正文与图形

- `chapters/`保存各章正文，`figures/`保存TikZ图与图形片段，`publication-assets/`保存公开源码中实际使用的截图裁片与矢量图。
- 界面文字使用`\ui{…}`，文件名使用`\file{…}`，步骤使用`steps`环境；含空格的短输入使用`\literalinput{…}`。
- 索引使用`\index{拼音排序词@中文主题}`；图像更新时同步核对步骤、图注、标签和索引。
- 科学结果图优先保留矢量PDF；截图裁片保持原生像素，不用上采样、补画或重打数值提高表面清晰度。
- 公共截图来源清单保留原图SHA与裁框，便于追溯；原始全屏文件留在编写档案中。

封面采用随书 `examples/silicon.cif` 的金刚石硅结构，将三个常规晶胞沿 `[100]` 方向拼接，以正交投影绘制原子和第一近邻键；青绿色键标出一组四面体配位。矢量源文件为 `figures/cover-silicon.tex`。需要重新生成时，在仓库根目录运行：

```sh
python3 docs/manual-zh/figures/generate_cover_silicon.py
```

生成器仅使用 Python 标准库，检查内部位点的四配位与四面体键角，并将几何核对记录写入 `output/cover-design/geometry.json`。封面与全书使用 `V0.5.0` 的版本写法。

可选重绘IDPP演示图时，另安装`numpy`和`matplotlib`，然后从本仓库根目录运行：

```sh
python3 -m pip install numpy matplotlib
python3 docs/manual-zh/figures/plot_neb_idpp.py
```

输出位于`output/figures/neb-idpp/`，包括PDF、PNG及来源记录。脚本只读取随书路径数据，不运行MATLAB®，也不覆盖`publication-assets/`。主PDF构建直接使用随附的发布图，不需要这两个可选Python库。

本README说明交付结构与构建方法。最终交付批次由对应的冻结源、PDF与案例清单识别，构建成功本身不代替操作核查和逐页校样。
