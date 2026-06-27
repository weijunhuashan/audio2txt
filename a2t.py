import argparse
import whisper
import os
from pathlib import Path

def main():
    # 创建命令行参数解析器
    parser = argparse.ArgumentParser(
        description="使用OpenAI Whisper将音频文件（M4A/MP3等）转换为文本"
    )
    
    # 添加参数
    parser.add_argument(
        "-i", "--input", 
        type=str, 
        required=True,
        help="输入的音频文件路径（支持: m4a, mp3, wav, flac, ogg等）"
    )
    
    parser.add_argument(
        "-o", "--output", 
        type=str, 
        default=None,
        help="输出的文本文件路径（可选，默认与输入文件同目录同名的.txt文件）"
    )
    
    parser.add_argument(
        "-m", "--model", 
        type=str, 
        choices=["tiny", "base", "small", "medium", "large"],
        default="base",
        help="选择Whisper模型大小（默认: base）"
    )
    
    parser.add_argument(
        "-l", "--language", 
        type=str, 
        default=None,
        help="指定音频语言（例如: zh, en, ja）。如果为None则自动检测"
    )
    
    parser.add_argument(
        "-f", "--format",
        type=str,
        choices=["txt", "srt", "vtt", "tsv", "json"],
        default="txt",
        help="输出格式（默认: txt）"
    )
    
    parser.add_argument(
        "-v", "--verbose", 
        action="store_true",
        help="显示详细处理信息"
    )
    
    # 解析参数
    args = parser.parse_args()
    
    # 检查输入文件是否存在
    if not os.path.exists(args.input):
        print(f"错误：输入文件 '{args.input}' 不存在！")
        return
    
    # 检查文件格式（仅提示，不强制限制）
    supported_formats = ['.m4a', '.mp3', '.wav', '.flac', '.ogg', '.aac', '.wma']
    input_ext = Path(args.input).suffix.lower()
    if input_ext not in supported_formats:
        print(f"警告：文件格式 '{input_ext}' 可能不被支持，继续尝试...")
        print(f"支持的格式: {', '.join(supported_formats)}")
    
    # 设置默认输出路径（如果未提供）
    if args.output is None:
        input_path = Path(args.input)
        args.output = input_path.with_suffix(f'.{args.format}').name
    
    # 确保输出目录存在
    output_dir = Path(args.output).parent
    if output_dir and not output_dir.exists():
        output_dir.mkdir(parents=True, exist_ok=True)
    
    if args.verbose:
        print(f"正在加载 '{args.model}' 模型...")
        print(f"输入文件: {args.input}")
        print(f"输出文件: {args.output}")
        print(f"输出格式: {args.format}")
        if args.language:
            print(f"指定语言: {args.language}")
    
    # 加载模型
    model = whisper.load_model(args.model)
    
    if args.verbose:
        print(f"开始转录文件: {args.input}")
    
    # 转录音频（Whisper自动处理各种格式，只要ffmpeg安装了）
    try:
        result = model.transcribe(
            args.input,
            language=args.language,
            verbose=args.verbose,
            task="transcribe"  # 也可以是 "translate"（翻译成英文）
        )
    except Exception as e:
        print(f"转录失败: {e}")
        print("请确保已安装 ffmpeg")
        print("安装方法:")
        print("  - Windows: 下载 https://ffmpeg.org/download.html 并添加到PATH")
        print("  - Mac: brew install ffmpeg")
        print("  - Linux: sudo apt install ffmpeg")
        return
    
    # 根据格式保存结果
    try:
        if args.format == "txt":
            # 保存为纯文本
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(result["text"])
            
        elif args.format in ["srt", "vtt", "tsv", "json"]:
            # 使用Whisper的内置写入器
            from whisper.utils import get_writer
            writer = get_writer(args.format, str(Path(args.output).parent))
            writer(result, args.output)
        
        if args.verbose:
            print(f"转录完成！结果已保存到: {args.output}")
            print(f"检测到的语言: {result.get('language', '未知')}")
            print(f"文本长度: {len(result['text'])} 字符")
        else:
            print(f"完成: {args.output}")
            
    except Exception as e:
        print(f"保存文件失败: {e}")

if __name__ == "__main__":
    main()