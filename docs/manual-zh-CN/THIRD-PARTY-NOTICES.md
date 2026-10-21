# 手册生成与字体映射

PDF 使用 TeX Live 随附的 Fandol 中文字体、TeX Gyre 西文字体、Latin Modern 以及 AMS Computer Modern 数学与等宽字体。字体由 TeX Live 提供，不在手册源代码中重新分发。

`build.py` 使用 Python、pypdf 和 XeLaTeX，均不需要 Java/JVM。导出的 PDF 内嵌 Adobe-GB1-UCS2 字符映射，便于不同阅读器显示、搜索和复制中文。映射从本机 TeX Live 的 adobemapping 包读取；以下保留其版权与许可。

新增大括号、矩阵定界符、求和与积分符号使用 TeX Live 的 CMEX10 字体。该字体由 American Mathematical Society 提供，按 SIL Open Font License 1.1 分发；嵌入文档不改变文档自身许可。字体文件仍由 TeX 环境提供。`build.py`依据同环境的`cmex10.afm`标准字符编码，为本书使用的扩展数学字符补充Unicode映射，不修改字形。

## Adobe-GB1-UCS2

```text
-----------------------------------------------------------
Copyright 1990-2019 Adobe. All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the
following conditions are met:

Redistributions of source code must retain the above
copyright notice, this list of conditions and the following
disclaimer.

Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials
provided with the distribution.

Neither the name of Adobe nor the names of its contributors
may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------
```
