# KSSOLV Toolbox 中文用户手册

本仓库独立维护 **KSSOLV Toolbox V0.5.0** 中文用户手册，包含正式 PDF、完整 LaTeX 源码、排版样式、插图和随书案例。手册共 **313 页**，适用于独立应用程序、MATLAB® 工具箱和 KSSOLV Toolbox Online 三种使用方式，涵盖运行准备、结构建模、计算及结果分析。

[阅读正式 PDF](dist/KSSOLV_Toolbox_User_Manual_zh-CN.pdf) · [源码与编辑说明](docs/manual-zh/README.md) · [随书案例](docs/manual-zh/examples/README.zh-CN.md)

## 重建手册

需要 Python 3，以及 TeX Live 2026 或提供相同宏包、字体的兼容环境。TeX 环境应提供 XeLaTeX、latexmk、MakeIndex、kpsewhich、ctex、Fandol、TeX Gyre、Latin Modern、AMS Computer Modern 和 adobemapping。详细依赖见[构建说明](docs/manual-zh/README.md)。

在仓库根目录运行：

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python build.py
```

生成的 PDF 位于 `output/pdf/KSSOLV_Toolbox_User_Manual_zh-CN.pdf`。构建脚本检查缺字、横向溢出和未定义引用，并补充必要的字体 Unicode 映射。构建无需安装 KSSOLV Toolbox、MATLAB® 或 Java/JVM。

迁移或调整构建环境后，可用以下命令逐页比较重建文件与正式 PDF 的文字、页面尺寸、版面内容流及嵌入字体和 Unicode 映射：

```sh
python tools/verify_pdf.py
```

`dist/` 保存经过校样的正式交付文件。重编译产物写入 `output/`，经核对后再更新正式文件。不同时间生成的 PDF 元数据可能不同，文件哈希不一定相同。

## 仓库内容

| 路径 | 内容 |
| --- | --- |
| `dist/` | 正式 PDF、版本信息与校验和 |
| `docs/manual-zh/main.tex` | 全书入口 |
| `docs/manual-zh/chapters/` | 各章正文 |
| `docs/manual-zh/manual-style.sty` | 页面、字体和正文样式 |
| `docs/manual-zh/figures/` | 可编辑图形及可选绘图脚本 |
| `docs/manual-zh/publication-assets/` | 正文使用的截图裁片和矢量图 |
| `docs/manual-zh/examples/` | 结构、项目、参考数据及 MATLAB® 示例 |
| `docs/manual-plan.zh-CN.md` | 编写计划与验收要求 |
| `docs/provenance/` | 导入来源、素材追溯与迁移核验记录 |

## 运行案例

阅读或重建手册不需要软件源码。运行 MATLAB® 参考案例时，另行准备配套的 KSSOLV Toolbox，并用 `KSSOLV_TOOLBOX_ROOT` 环境变量指定其目录，或使用 MATLAB® 已能定位的工具箱安装。无图形案例使用 `-nojvm`；各例的输入、单位和参考结果见[案例说明](docs/manual-zh/examples/README.zh-CN.md)。

正式插图已包含在仓库中。可选的 NEB/IDPP 图形重绘脚本另需 NumPy 和 Matplotlib，重绘文件进入 `output/figures/neb-idpp/`，不自动替换已校样插图。

## 版本与来源

本仓库从 V0.5.0 正式交付源包独立建立；导入基线保存在 `docs/provenance/source-import-0.5.0.json`，其中的哈希描述导入前的源包文件。独立仓库的后续修改以 Git 历史为准。迁移时保留已校样的正文、页面样式、发布素材、参考数据与 PDF，调整案例的路径配置及构建入口。

仓库保留原有 [LICENSE](LICENSE) 与[商业许可说明](COMMERCIAL-LICENSE.md)。第三方字体、映射和案例数据的说明见[第三方许可索引](THIRD-PARTY-LICENSES.md)。
