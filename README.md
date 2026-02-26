# show_words

在 Ubuntu 终端中背单词与默写小测试：基于 IELTS 词表 YAML，纯 Shell + AWK 实现，无 Python 依赖，占用低。

## 功能

- **背单词**：显示拼写、音标（含中括号，如 `[ɪnˈkredəbl]`）、中文释义、例句；支持上下键切换；退出时保存进度，下次从上次位置继续。
- **小测试**：仅从**已学习过的范围**（即背单词进度以内的词）出题，根据中文释义和音标输入英文拼写，自动判对错并统计正确率。

## 环境要求

- Bash
- AWK（如 `gawk`，Ubuntu 默认已装）
- 终端需支持方向键（背单词模式下使用）

词表目录默认为本目录下的 `data/ielts-word-list`，其中需包含 `word-list-*.yaml` 文件。

## 目录结构

```
show_words/
├── README.md        # 本说明
├── show_words       # 入口脚本（可执行）
├── parse_words.awk  # YAML 解析脚本
├── data/
│   └── ielts-word-list/   # 词表目录（内含 word-list-*.yaml）
└── study_progress   # 背单词进度（自动生成，可删以从头开始）
```

## 用法

### 统一入口（推荐）

直接运行脚本，先选择模式再进入对应功能：

```bash
cd /path/to/vocabulary/show_words
./show_words
```

会显示菜单：

```
  show_words - IELTS 背单词 / 小测试

  请选择模式:

    1) 背单词  - 上下键切换，从上次位置继续
    2) 小测试  - 根据释义与音标拼写，默认 20 题

  请输入 1 或 2:
```

- 输入 **1**（或 `study`、`s`）进入背单词。
- 输入 **2**（或 `quiz`、`q`）进入小测试；接着会询问题数，直接回车即默认 20 题。

### 直接指定模式

也可跳过菜单，直接传子命令：

```bash
./show_words study        # 背单词
./show_words quiz         # 小测试，默认 20 题
./show_words quiz 50      # 小测试，50 题
```

### 背单词（study）

从**上次结束位置**继续背诵，支持上下键翻词、按 `q` 退出并保存进度。

- **↑**：上一词  
- **↓**：下一词  
- **q**：退出并保存当前进度  

界面会显示「第 x / 共 N 词」以及当前词的拼写、音标、释义、例句。退出时会提示「已保存进度: 第 x / N 词」。

若要**从头开始**，删除进度文件后再运行：

```bash
rm -f study_progress
./show_words study
# 或先运行 ./show_words，再选 1
```

### 小测试（quiz）

根据**中文释义和音标**输入英文单词，程序会判对错并显示正确答案与统计。

- **出题范围**：只从**已学习过的词**中出题（即当前背单词进度以内的词）。若尚未背过任何词，会提示「请先进行背单词以积累学习范围」。
- 题目在已学习范围内**随机抽取**，不重复。
- 判题时**忽略首尾空格**和**大小写**（如输入 `Emperor` 与 `emperor` 均算对）。
- 每道题会显示「第 x / 共 M 题」；全部做完后显示「正确 n / 共 M 题」。
- 若指定题数大于已学习词数，则实际出题数等于已学习词数。

```bash
./show_words quiz        # 默认 20 题（在已学习范围内）
./show_words quiz 50     # 50 题
```

## 配置与路径

通过环境变量可自定义词表目录和进度文件位置（不设置则使用脚本所在目录的相对路径）：

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `SHOW_WORDS_LIST_DIR` | 词表目录（内含 `word-list-*.yaml`） | 脚本所在目录的 `data/ielts-word-list` |
| `SHOW_WORDS_PROGRESS` | 背单词进度文件路径 | 脚本所在目录的 `study_progress` |

示例：

```bash
# 使用自定义词表目录
export SHOW_WORDS_LIST_DIR=/home/user/my-ielts-lists
./show_words study

# 进度文件放到用户配置目录
export SHOW_WORDS_PROGRESS=~/.config/show_words/study_progress
./show_words study
```

## 词表格式

**词表来源**：IELTS 词表数据来自 [sxwang1991/ielts-word-list](https://github.com/sxwang1991/ielts-word-list)（雅思词汇词根+联想记忆法：乱序便携版）。本项目中词表放在 [data/ielts-word-list](data/ielts-word-list) 目录下。

其中所有匹配 `word-list-*.yaml` 的文件会按文件名排序后**合并**成一张总词表。每个 YAML 中词条需包含：

- `title`：单词拼写（可为空，此时用词条 key）
- `text`：含音标 `[...]` 与释义，可多行
- `example`：例句（可选）

解析逻辑见 [parse_words.awk](parse_words.awk)，兼容无 example、title 为空、无音标等格式变体。

## 常见问题

- **背单词时按键没反应**：请在**真实终端**（如 Ubuntu 自带的 Terminal）中运行，不要在 IDE 内置终端或管道重定向下使用，否则方向键可能无法识别。
- **提示 "list directory not found"**：检查 `SHOW_WORDS_LIST_DIR` 或默认的 `data/ielts-word-list` 目录是否存在，且其中是否有 `word-list-*.yaml`。
- **小测试提示「请先进行背单词以积累学习范围」**：小测试只从已学习过的词中出题。先运行背单词模式并至少看过一个词、退出保存进度后，再使用小测试。
- **进度错乱或想重置**：删除 `study_progress`（或 `SHOW_WORDS_PROGRESS` 指向的文件）后重新运行 `./show_words study`。
