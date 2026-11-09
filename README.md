# a2t.py 用户手册

## 1. 概述

`a2t.py` 是一个基于 **OpenAI Whisper** 的命令行音频转文字工具。它可以将常见的音频文件（如 M4A、MP3、WAV、FLAC、OGG 等）转录为文本，并支持多种输出格式：

- 纯文本 `txt`
- 字幕 `srt`
- 网页字幕 `vtt`
- 制表符分隔文本 `tsv`
- JSON `json`

脚本会调用 Whisper 模型完成语音识别，支持自动检测语言，也可以手动指定语言（如中文、英文、日文）。

> 注意：当前命令行接口只执行 **转录（transcribe）**，不提供翻译为英文的选项。

---

## 2. 环境要求

### 2.1 Python 依赖

```bash
pip install openai-whisper
```

Whisper 会自动安装 PyTorch 等依赖。如需 GPU 加速，请根据你的 CUDA 环境安装对应版本的 PyTorch。

### 2.2 系统依赖：ffmpeg

Whisper 依赖 `ffmpeg` 读取音频文件。请确保 `ffmpeg` 已安装并在 `PATH` 中可用。

**Windows**

1. 从 <https://ffmpeg.org/download.html> 下载 Windows 版本
2. 解压后将 `bin` 目录加入系统 `PATH`
3. 在命令行验证：

```bash
ffmpeg -version
```

**macOS**

```bash
brew install ffmpeg
```

**Linux（Debian/Ubuntu）**

```bash
sudo apt update
sudo apt install ffmpeg
```

### 2.3 模型下载

首次使用某个模型时，Whisper 会自动下载模型文件，需要网络连接。模型会缓存到本地，后续可离线使用。

---

## 3. 快速开始

### 3.1 最简单的用法

```bash
python a2t.py -i meeting.m4a
```

- 使用默认模型 `base`
- 自动检测语言
- 输出格式为 `txt`
- 默认输出到**当前工作目录**，文件名为 `meeting.txt`

### 3.2 指定输出文件和模型

```bash
python a2t.py -i audio.mp3 -o transcripts/audio.txt -m small -l zh -v
```

说明：

- 使用 `small` 模型
- 指定语言为中文 `zh`
- 输出到 `transcripts/audio.txt`
- `-v` 显示详细处理信息

### 3.3 生成 SRT 字幕

```bash
python a2t.py -i lecture.wav -o lecture.srt -f srt -m medium
```

### 3.4 生成 JSON 结果

```bash
python a2t.py -i interview.flac -o interview.json -f json -l en
```

---

## 4. 命令行参数

| 参数 | 简写 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--input` | `-i` | 是 | — | 输入音频文件路径。支持 `m4a`、`mp3`、`wav`、`flac`、`ogg`、`aac`、`wma` 等，实际支持范围取决于 `ffmpeg` |
| `--output` | `-o` | 否 | 当前工作目录下同名文件 | 输出文件路径。可包含目录，脚本会尝试创建不存在的父目录 |
| `--model` | `-m` | 否 | `base` | Whisper 模型大小：`tiny`、`base`、`small`、`medium`、`large` |
| `--language` | `-l` | 否 | 自动检测 | 指定音频语言，例如 `zh`、`en`、`ja` |
| `--format` | `-f` | 否 | `txt` | 输出格式：`txt`、`srt`、`vtt`、`tsv`、`json` |
| `--verbose` | `-v` | 否 | 关闭 | 显示详细处理信息，并把详细模式传给 Whisper |

### 4.1 模型大小选择

| 模型 | 相对速度 | 相对准确度 | 适用场景 |
|---|---|---|---|
| `tiny` | 最快 | 最低 | 快速预览、低资源环境 |
| `base` | 快 | 较低 | 默认选择，日常短音频 |
| `small` | 中等 | 较好 | 质量与速度平衡 |
| `medium` | 较慢 | 高 | 对准确度要求较高 |
| `large` | 最慢 | 最高 | 高质量转录，需要较多内存/显存 |

> 模型越大，转录质量通常越好，但速度更慢、资源消耗更高。长音频建议先用 `tiny` 或 `base` 测试流程。

### 4.2 常用语言代码

| 语言 | 代码 |
|---|---|
| 中文 | `zh` |
| 英文 | `en` |
| 日文 | `ja` |
| 韩文 | `ko` |
| 法文 | `fr` |
| 德文 | `de` |
| 西班牙文 | `es` |

不指定 `-l` 时，Whisper 会自动检测语言。

---

## 5. 输出格式说明

| 格式 | 扩展名 | 内容 |
|---|---|---|
| `txt` | `.txt` | 纯文本转录结果，只包含识别文本 |
| `srt` | `.srt` | SubRip 字幕，包含时间轴 |
| `vtt` | `.vtt` | WebVTT 字幕，适合网页播放器 |
| `tsv` | `.tsv` | 制表符分隔的片段级结果 |
| `json` | `.json` | 结构化结果，包含文本、片段、时间戳等信息 |

### 5.1 关于默认输出路径

脚本帮助文本写的是“默认与输入文件同目录同名”，但当前实现实际是：

```python
args.output = input_path.with_suffix(f'.{args.format}').name
```

因此**未指定 `-o` 时，输出文件会生成在当前工作目录**，文件名为原音频文件名加上所选格式扩展名。

例如：

```bash
cd /data/work
python /path/to/a2t.py -i /data/audio/meeting.m4a
```

输出为：

```text
/data/work/meeting.txt
```

如果需要输出到指定目录，建议显式使用 `-o`：

```bash
python a2t.py -i /data/audio/meeting.m4a -o /data/audio/meeting.txt
```

### 5.2 文件覆盖提醒

如果输出文件已存在，脚本会直接覆盖（`txt` 使用写入模式，Whisper writer 也会生成同名文件）。请提前备份重要文件，或使用不同的输出路径。

---

## 6. 使用示例

### 6.1 自动检测语言，输出纯文本

```bash
python a2t.py -i recording.m4a
```

### 6.2 指定中文和 small 模型

```bash
python a2t.py -i recording.m4a -m small -l zh -v
```

### 6.3 输出到指定目录

```bash
python a2t.py \
  -i recordings/meeting.mp3 \
  -o output/meeting.txt \
  -m medium \
  -l zh \
  -v
```

### 6.4 生成字幕文件

```bash
python a2t.py -i video_audio.wav -o subtitle.srt -f srt -m small
```

### 6.5 生成 VTT 字幕

```bash
python a2t.py -i podcast.ogg -o podcast.vtt -f vtt
```

### 6.6 生成 JSON 结构化结果

```bash
python a2t.py -i interview.flac -o interview.json -f json -l en -m medium
```

### 6.7 快速低资源测试

```bash
python a2t.py -i long_audio.mp3 -m tiny -f txt
```

---

## 7. 工作流程

脚本执行流程如下：

1. 解析命令行参数
2. 检查输入文件是否存在
3. 根据扩展名给出格式提示（不强制限制）
4. 如果未指定 `-o`，根据输入文件名和输出格式生成默认输出路径
5. 创建输出目录（如果指定了不存在的父目录）
6. 加载指定 Whisper 模型
7. 调用 `model.transcribe()` 转录音频
8. 按所选格式保存结果
9. 输出完成信息

---

## 8. 常见问题与排查

### 8.1 输入文件不存在

错误信息：

```text
错误：输入文件 'xxx' 不存在！
```

处理：检查路径是否正确；路径包含空格时请使用引号：

```bash
python a2t.py -i "my audio file.m4a"
```

### 8.2 转录失败，提示安装 ffmpeg

可能输出：

```text
转录失败: ...
请确保已安装 ffmpeg
```

处理：

- 确认 `ffmpeg -version` 可正常执行
- 如果刚安装 ffmpeg，请重新打开终端
- Windows 用户确认 `ffmpeg.exe` 所在目录已加入 `PATH`

### 8.3 模型下载慢或失败

首次运行会下载模型。若网络受限，可：

- 使用较小模型（如 `tiny` 或 `base`）
- 配置代理
- 手动预下载模型并放到 Whisper 缓存目录

### 8.4 内存或显存不足

使用较大的 `medium`、`large` 模型时可能内存/显存不足。处理：

- 改用 `small`、`base` 或 `tiny`
- 关闭其他占用资源的程序
- 对长音频先切分成较短片段

### 8.5 输出路径不符合预期

未指定 `-o` 时，输出文件位于**当前工作目录**，不是输入文件所在目录。建议始终显式指定 `-o`：

```bash
python a2t.py -i /path/to/audio.m4a -o /path/to/output.txt
```

### 8.6 文件格式警告

如果扩展名不在以下列表中，会给出警告但继续尝试：

```text
.m4a .mp3 .wav .flac .ogg .aac .wma
```

实际能否读取取决于 `ffmpeg`。如果失败，可先用 ffmpeg 转换为 `wav`：

```bash
ffmpeg -i input.unknown -ar 16000 -ac 1 output.wav
```

### 8.7 语言检测不准确

短音频或混合语言音频可能检测错误。建议手动指定语言：

```bash
python a2t.py -i audio.m4a -l zh
```

### 8.8 保存文件失败

可能原因：

- 输出目录无写权限
- 路径包含非法字符
- 目标文件被其他程序占用

处理：更换输出目录或文件名，确保有写权限。

---

## 9. 注意事项与限制

- 当前 CLI **不提供翻译功能**，只进行转录。
- 输入文件格式检查仅为提示，不强制阻止。
- 输出文件可能被覆盖，请自行备份。
- 长音频转录耗时较长，耗时与模型大小、音频长度、硬件性能有关。
- 首次使用模型需要联网下载。
- `verbose` 模式会输出 Whisper 的详细进度信息。
- 输出文本使用 UTF-8 编码。
- 该工具面向音频文件；虽然 ffmpeg 可能能读取视频容器中的音频，但本手册建议先提取音频。

---

## 10. 完整参数速查

```text
用法：
  python a2t.py -i INPUT [选项]

必填：
  -i, --input INPUT          输入音频文件路径

可选：
  -o, --output OUTPUT        输出文件路径
  -m, --model MODEL          模型：tiny/base/small/medium/large，默认 base
  -l, --language LANGUAGE    语言代码，如 zh、en、ja；默认自动检测
  -f, --format FORMAT        输出格式：txt/srt/vtt/tsv/json，默认 txt
  -v, --verbose              显示详细处理信息
  -h, --help                 显示帮助
```

---

## 11. 最小工作示例

```bash
# 1. 安装依赖
pip install openai-whisper

# 2. 确认 ffmpeg
ffmpeg -version

# 3. 基本转录
python a2t.py -i sample.m4a

# 4. 指定中文、small 模型、详细输出
python a2t.py -i sample.m4a -m small -l zh -v

# 5. 生成 SRT 字幕到指定目录
python a2t.py -i sample.m4a -o output/sample.srt -f srt -m small

# 6. 查看帮助
python a2t.py -h
```

