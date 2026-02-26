# vocab-tty

终端背 IELTS 词表 + 拼写小测，Shell + AWK 实现，无 Python 依赖。

---

## 逻辑与功能概览

**运行逻辑**：词表为分册 YAML（`word-list-01.yaml`～`word-list-48.yaml`），脚本启动时用 `parse_words.awk` 解析为 TSV（单词、音标、释义、例句），背单词时按当前进度显示并保存进度索引，小测试从「已学习范围」内随机抽题、根据释义与音标输入拼写判对错。

**功能**：

- **背单词（study）**：显示拼写、音标、释义、例句；↑/↓ 翻词，`q` 退出并保存进度，下次从上次位置继续。
- **小测试（quiz）**：仅从已学习过的词中出题，根据释义和音标输入英文，自动判对错并统计正确数。

---

## 环境要求

- Bash、AWK（如 `gawk`，Ubuntu 一般已装）
- 背单词需在**真实终端**中运行（方向键在 IDE 内置终端或管道下可能无效）

---

## 目录结构

```
vocab-tty/
├── README.md
├── show_words          # 入口脚本（可执行）
├── parse_words.awk     # 词表 YAML → TSV 解析
├── data/
│   └── ielts-word-list/   # 词表目录（内含 word-list-01.yaml 等）
└── study_progress      # 进度文件（自动生成，可删以重置）
```

---

## 使用方法

### 快速开始

```bash
cd /path/to/vocab-tty
./show_words
```

按提示输入 **1** 背单词或 **2** 小测试；小测试会询问题数，回车默认 20 题。

### 子命令（跳过菜单）

```bash
./show_words study        # 背单词
./show_words quiz         # 小测试，默认 20 题
./show_words quiz 50      # 小测试，50 题
```

### 背单词操作

- **↑**：上一词  
- **↓**：下一词  
- **q**：退出并保存进度  

界面显示「第 x / 共 N 词」及当前词的拼写、音标、释义、例句。退出时提示「已保存进度: 第 x / N 词」。

**从头开始**：删除进度文件后再运行背单词即可。

```bash
rm -f study_progress
./show_words study
```

### 小测试规则

- 出题范围：仅**已学习过的词**（即当前背单词进度以内的词）；未背过任何词时会提示先背单词。
- 题目在已学范围内随机抽取，不重复。
- 判题忽略首尾空格和大小写。
- 若指定题数大于已学词数，则实际题数等于已学词数。

---

## 路径与配置（词汇文件、进度文件）

通过环境变量指定**词表目录**和**进度文件路径**；不设置时使用脚本所在目录下的默认路径。

### 环境变量说明

| 变量 | 含义 | 默认值 |
|------|------|--------|
| `SHOW_WORDS_LIST_DIR` | 词表所在目录（其下需有 `word-list-*.yaml`） | `脚本所在目录/data/ielts-word-list` |
| `SHOW_WORDS_PROGRESS` | 进度文件路径（保存当前背到第几个词） | `脚本所在目录/study_progress` |

脚本会读取 `SHOW_WORDS_LIST_DIR` 下所有匹配 `word-list-*.yaml` 的文件（如 `word-list-01.yaml`、`word-list-02.yaml`），按文件名数字排序后合并为一张总词表。**不会**读取无数字的 `word-list.yaml`。

### 使用自定义词表目录

词表放在其他目录时，设置 `SHOW_WORDS_LIST_DIR` 指向该目录即可：

```bash
export SHOW_WORDS_LIST_DIR=/home/user/my-vocab-lists
./show_words study
```

要求：该目录下存在至少一个 `word-list-*.yaml` 文件（如 `word-list-01.yaml`）。

### 使用自定义进度文件路径

例如把进度放到用户配置目录，便于多设备或重装后保留：

```bash
export SHOW_WORDS_PROGRESS=~/.config/vocab-tty/study_progress
./show_words study
```

可先创建目录：`mkdir -p ~/.config/vocab-tty`。

### 持久化配置

在 `~/.bashrc` 或 `~/.zshrc` 中写入后，每次打开终端即生效：

```bash
# 自定义词表目录（按需修改路径）
export SHOW_WORDS_LIST_DIR=/path/to/your/word-lists

# 进度文件放到配置目录（可选）
export SHOW_WORDS_PROGRESS=~/.config/vocab-tty/study_progress
```

然后执行 `source ~/.bashrc` 或重新打开终端。

### 路径错误时

- 若提示 **"list directory not found"**：检查 `SHOW_WORDS_LIST_DIR`（或默认的 `data/ielts-word-list`）是否存在。
- 若提示 **"no word-list-*.yaml"**：检查该目录下是否有至少一个 `word-list-NN.yaml` 文件（如 `word-list-01.yaml`）。

---

## 词表格式与来源

词表数据来自 [sxwang1991/ielts-word-list](https://github.com/sxwang1991/ielts-word-list)（雅思词汇词根+联想记忆法）。本仓库在 [data/ielts-word-list](data/ielts-word-list) 下已包含分册 YAML。

每册为 `word-list-NN.yaml`，词条字段：

- `title`：单词拼写（可省，则用词条 key）
- `text`：音标 `[...]` 与释义，可多行
- `example`：例句（可选）

解析由 [parse_words.awk](parse_words.awk) 完成，输出 TSV 供 `show_words` 使用。

---

## 常见问题

- **背单词时方向键/按键无反应**：在系统自带终端（如 Ubuntu Terminal）中运行，避免在 IDE 内置终端或通过管道重定向运行。
- **小测试提示「请先进行背单词以积累学习范围」**：先运行背单词并至少看过一个词、退出保存进度后，再运行小测试。
- **进度错乱或想重置**：删除 `study_progress`（或 `SHOW_WORDS_PROGRESS` 指向的文件）后重新运行 `./show_words study`。
