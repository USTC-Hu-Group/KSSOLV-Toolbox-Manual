# Volume parser fixtures

The four files listed below are frozen, redistributable test inputs from
[`materialsproject/pymatgen-core`](https://github.com/materialsproject/pymatgen-core)
at commit `c71faa7a95df9bbcd20cb3d14ff112d0f72d8e39` (tag
`v2026.7.24`, MIT license).

| Local file | Upstream path | SHA-256 |
| --- | --- | --- |
| `CHGCAR.nospin.gz` | `test-files/io/vasp/outputs/CHGCAR.nospin.gz` | `1d0f7cab991845fb6b5576839727948d189d339e908c5908ea8ffd935337a715` |
| `CHGCAR.spin.gz` | `test-files/io/vasp/outputs/CHGCAR.spin.gz` | `43c3b6db491b08868f8e49b3114396c88090dd47aa7837eac27729865756253e` |
| `elec.cube.gz` | `test-files/command_line/bader/elec.cube.gz` | `4d3e32d374920e2a1210ebc718ad2f358751ea1861190281fce2ad4d2a0fb8df` |
| `datagrid_3d.xsf` | `test-files/io/xcrysden/datagrid_3d.xsf` | `c0a8ec512661c1ffa4c20fb922f52972ee825c01078976e2ee076729b60972c5` |

In the original software repository these fixtures were stored beside
`VolumeIOTest.m` to test the public FileParser contract. The software's test
sources and their generated malformed-input fixtures are not included in
this independent manual repository; the four data files above are included
here for the manual's volume-data exercises.

## 中文手册中的副本

本文件的来源记录取自编写时软件仓库的
`+kssolv/+services/+fileparser/+test/Volume/README.md`（该软件文件不随手册提供），保留四个上游测试文件的冻结来源与 SHA-256。手册中的
`CHGCAR.nospin.gz`、`CHGCAR.spin.gz`、`elec.cube.gz`、`datagrid_3d.xsf`
均为相同文件的副本。

对应 MIT 许可与版权声明保存在同目录 `PYMATGEN-MIT-LICENSE.txt`，
原文取自编写时软件仓库的
`+kssolv/+analysis/+matgenlab/docs/THIRD_PARTY_NOTICES.md`
的 pymatgen/pymatgen-core 许可部分。

`CHGCAR-teaching` 另从编写时软件仓库的 Volume 夹具 `CHGCAR` 复制，
不属于上表四个已列 SHA-256 的冻结上游文件；它仅作为手册的附加查看示例。

该附加副本的本地SHA-256为：

```text
6193b92c72a319a50a89754ec89255c1958974bd4d374c7933ac5be25620f7af  CHGCAR-teaching
```

此哈希仅用于核对随书副本，不将上表四份文件的上游来源或MIT许可推定到该附加文件。
