# vocab-tty

终端背单词 + 拼写小测，支持多种考试词表（雅思 / CET-4·6 / 考研 / SAT / TOEFL）。Shell + AWK + jq，无 Python 依赖。

---

## 逻辑与功能概览

**运行逻辑**：通过同目录下的 **config** 选择当前考试；词表为 YAML（雅思）或 JSON（其他考试），统一解析为 TSV（单词、音标、释义、例句）。背单词按当前进度显示并保存进度索引，小测试从「已学习范围」内随机抽题、根据释义与音标输入拼写判对错。

**功能**：

- **背单词（study）**：显示拼写、音标、释义、例句；↑/↓ 翻词，`q` 退出并保存进度，下次从上次位置继续。
- **小测试（quiz）**：仅从已学习过的词中出题，根据释义和音标输入英文，自动判对错并统计正确数。
- **设置（config）**：首次运行或更换考试时选择考试类型，配置与进度均保存在项目目录。

---

## 环境要求

- Bash、AWK（如 `gawk`，Ubuntu 一般已装）
- 使用 **JSON 词表**（CET-4/6、考研、SAT、TOEFL）时需安装 **jq**
- 背单词需在**真实终端**中运行（方向键在 IDE 内置终端或管道下可能无效）

---

## 目录结构

```
vocab-tty/
├── README.md
├── vocab-tty           # 入口脚本（可执行）
├── parse_words.awk     # 雅思词表 YAML → TSV 解析
├── config              # 用户配置（首次运行或 config 子命令生成，可 .gitignore）
├── config.example      # 配置示例与字段说明
├── data/
│   ├── ielts-word-list/   # 雅思：word-list-*.yaml
│   ├── CET-4/             # CET4.json
│   ├── CET-6/             # CET6.json
│   ├── Graduate-Entrance/ # Graduate-Entrance.json
│   ├── SAT/               # SAT.json
│   └── TOEFL/             # TOEFL.json
└── study_progress.<exam>  # 进度文件（按考试隔离，如 study_progress.ielts-word-list）
```

---

## 使用方法

### 快速开始

```bash
cd /path/to/vocab-tty
./vocab-tty
```

**首次运行**：若没有 `config`，会提示选择考试类型（根据 `data/` 下已有词表列出），选择后自动生成 `config` 并进入主菜单。

**主菜单**：输入 **1** 背单词、**2** 小测试、**3** 设置（更换考试）。小测试会询问题数，回车默认 20 题。

### 子命令（跳过菜单）

```bash
./vocab-tty study        # 背单词
./vocab-tty quiz         # 小测试，默认 20 题
./vocab-tty quiz 50      # 小测试，50 题
./vocab-tty config       # 重新选择考试类型并写回 config
```

### 背单词操作

- **↑**：上一词  
- **↓**：下一词  
- **q**：退出并保存进度  

界面显示「第 x / 共 N 词」及当前词的拼写、音标、释义、例句。退出时提示「已保存进度: 第 x / N 词」。

**从头开始**：删除当前考试的进度文件后再运行背单词即可（进度文件名为 `study_progress.<考试ID>`，见下方配置说明）。

### 小测试规则

- 出题范围：仅**已学习过的词**（即当前背单词进度以内的词）；未背过任何词时会提示先背单词。
- 题目在已学范围内随机抽取，不重复。
- 判题忽略首尾空格和大小写。
- 若指定题数大于已学词数，则实际题数等于已学词数。

---

## 配置文件（config）

配置文件位于**主程序同目录**：`vocab-tty` 所在目录下的 `config`。不使用环境变量或用户目录。

### 字段说明

| 字段 | 含义 | 默认值 |
|------|------|--------|
| `exam` | 当前使用的考试 ID（对应 `data/` 下子目录名） | 无，首次运行需选择 |
| `data_dir` | 词表根目录（其下每个子目录为一类考试） | 脚本所在目录/data |
| `progress_dir` | 进度文件所在目录 | 脚本所在目录 |

**派生规则**：

- 词表目录 = `data_dir/<exam>/`（如 `data/ielts-word-list/` 或 `data/CET-4/`）
- 进度文件 = `progress_dir/study_progress.<exam>`（如 `study_progress.ielts-word-list`），按考试隔离，切换考试不影响其他考试进度。

### 首次使用与更换考试

- 无 `config` 或 `exam` 为空时，运行 `./vocab-tty` 会进入“选择考试”流程并生成 `config`。
- 使用 `./vocab-tty config` 或主菜单 **3) 设置** 可重新选择考试，写回同一 `config`。

可复制 `config.example` 为 `config` 后手动编辑；也可直接运行程序按提示选择。

### 词表格式

- **雅思**：`data/ielts-word-list/` 下为分册 `word-list-01.yaml`～`word-list-48.yaml`，由 `parse_words.awk` 解析。
- **其他考试（JSON）**：`data/<考试ID>/` 下为 `*.json`，需安装 **jq**。每项含：
  - `word`：单词（学习与测验只考该词，测验时根据释义输入英文单词校验）。
  - `translations`：`[{ "translation": "释义", "type": "adv"|"v"|"n"|"adj"|... }]`，词性 + 汉语意思；背词与测验时释义显示为「词性. 释义」（如 `adv. 突然地`）。
  - `phrases`（可选）：`[{ "phrase": "英文词组", "translation": "中文意思" }]`；背词时在例句区展示「词组 — 释义」。

### 词表来源与致谢

- **雅思词表**：来源于 [sxwang1991/ielts-word-list](https://github.com/sxwang1991/ielts-word-list)（雅思词汇词根+联想记忆法：乱序便携版）。感谢作者的开源分享。
- **其他考试词表（CET-4/6、考研、SAT、TOEFL 等）**：来源于 [KyleBing/english-vocabulary](https://github.com/KyleBing/english-vocabulary)，该仓库提供四六级、考研、托福、SAT 等英文词汇的 txt 与 json 版本。感谢 [KyleBing](https://github.com/KyleBing) 的整理与开源。

本仓库的 `data/` 下可放置上述词表数据，或按相同格式自行准备词表使用。

---

## 常见问题

- **背单词时方向键/按键无反应**：在系统自带终端（如 Ubuntu Terminal）中运行，避免在 IDE 内置终端或通过管道重定向运行。
- **小测试提示「请先进行背单词以积累学习范围」**：先运行背单词并至少看过一个词、退出保存进度后，再运行小测试。
- **进度错乱或想重置**：删除当前考试的进度文件（如 `study_progress.ielts-word-list`）后重新运行 `./vocab-tty study`。
- **使用 JSON 词表时报错「需要 jq」**：安装 jq（如 `apt install jq` 或 `brew install jq`）。
- **旧版仅有一个 study_progress 文件**：首次使用雅思且存在旧 `study_progress` 时，程序会自动复制为 `study_progress.ielts-word-list`。
