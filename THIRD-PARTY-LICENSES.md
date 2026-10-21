# 第三方许可索引

本仓库保留随手册交付的素材和案例来源说明：

- [排版工具、字体及 Adobe 字符映射](docs/manual-zh-CN/THIRD-PARTY-NOTICES.md)。字体由 TeX 发行版提供；手册 PDF 内嵌所需字体和字符映射。
- [体数据来源](docs/manual-zh-CN/examples/VOLUME-SOURCES.md)。
- [pymatgen MIT 许可](docs/manual-zh-CN/examples/PYMATGEN-MIT-LICENSE.txt)。
- [发布素材追溯记录](docs/provenance/ASSET-PROVENANCE.json)。

Python 依赖由 `requirements.txt` 声明并单独安装，不在本仓库中捆绑分发。运行 MATLAB 案例所需的 KSSOLV Toolbox 软件也须另行安装；其依赖与许可随软件发行。

繁体中文转换使用 [opencc-python-reimplemented](https://github.com/yichen0831/opencc-python)，采用 Apache-2.0 许可，包含 OpenCC 字典及台湾用语转换配置。这是纯 Python 实现，不使用需要编译的 OpenCC 绑定，也不需要 Java/JVM。

繁体中文 PDF 另使用 [Noto CJK 台湾字体](https://github.com/notofonts/noto-cjk)，采用 SIL Open Font License 1.1。`tools/download_tw_fonts.py` 下载固定版本的预编译 OTF 字体及许可文本，并校验 SHA256；字体保存在 `output/fonts/noto-cjk/`，不在仓库中捆绑分发。
