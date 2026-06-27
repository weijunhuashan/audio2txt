#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
MODEL="medium"           # 使用的Whisper模型
LANGUAGE="zh"            # 语言设置（留空则自动检测）
FORMAT="txt"           # 输出格式
VERBOSE=false          # 是否显示详细信息
PYTHON_SCRIPT="a2t.py"  # Python脚本名称

# 统计变量
total_files=0
success_count=0
fail_count=0
skipped_count=0

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用说明
show_usage() {
    cat << EOF
使用方法: ./transcribe_all.sh [选项]

选项:
  -m, --model MODEL     选择Whisper模型 (tiny, base, small, medium, large)
                        默认: base
  -l, --language LANG   指定语言代码 (zh, en, ja等)，默认自动检测
  -f, --format FORMAT   输出格式 (txt, srt, vtt, tsv, json)
                        默认: txt
  -v, --verbose         显示详细处理信息
  -h, --help            显示此帮助信息

示例:
  ./transcribe_all.sh                          # 使用默认设置处理所有音频
  ./transcribe_all.sh -m small -l zh          # 使用small模型，中文
  ./transcribe_all.sh -f srt -v               # 输出SRT字幕，显示详细信息

EOF
}

# 检查Python脚本是否存在
check_script() {
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        print_error "找不到 Python 脚本: $PYTHON_SCRIPT"
        print_info "请确保 $PYTHON_SCRIPT 在当前目录中"
        exit 1
    fi
}

# 处理单个文件
process_file() {
    local input_file="$1"
    local output_file="${input_file%.*}.${FORMAT}"
    
    # 检查是否已经存在输出文件
    if [ -f "$output_file" ]; then
        print_warning "跳过已存在的文件: $output_file"
        ((skipped_count++))
        return 0
    fi
    
    print_info "正在处理: $input_file"
    
    # 构建命令
    local cmd="python $PYTHON_SCRIPT -i \"$input_file\" -o \"$output_file\" -m $MODEL -f $FORMAT"
    
    if [ -n "$LANGUAGE" ]; then
        cmd="$cmd -l $LANGUAGE"
    fi
    
    if [ "$VERBOSE" = true ]; then
        cmd="$cmd -v"
    fi
    
    # 执行命令
    if eval $cmd; then
        print_success "完成: $output_file"
        ((success_count++))
        return 0
    else
        print_error "处理失败: $input_file"
        ((fail_count++))
        return 1
    fi
}

# 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model)
                MODEL="$2"
                shift 2
                ;;
            -l|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 检查Python脚本
    check_script
    
    # 显示配置信息
    echo "=========================================="
    print_info "Whisper 批量转录工具"
    echo "=========================================="
    print_info "模型: $MODEL"
    [ -n "$LANGUAGE" ] && print_info "语言: $LANGUAGE" || print_info "语言: 自动检测"
    print_info "输出格式: $FORMAT"
    [ "$VERBOSE" = true ] && print_info "详细模式: 开启"
    echo "=========================================="
    
    # 查找所有 MP3 和 M4A 文件
    print_info "正在搜索音频文件..."
    
    # 使用数组存储文件列表
    audio_files=()
    while IFS= read -r -d '' file; do
        audio_files+=("$file")
    done < <(find . -type f \( -iname "*.mp3" -o -iname "*.m4a" \) -print0)
    
    total_files=${#audio_files[@]}
    
    if [ $total_files -eq 0 ]; then
        print_warning "未找到任何 MP3 或 M4A 文件"
        exit 0
    fi
    
    print_info "找到 $total_files 个音频文件"
    echo "=========================================="
    
    # 处理每个文件
    for file in "${audio_files[@]}"; do
        process_file "$file"
    done
    
    # 显示统计信息
    echo "=========================================="
    print_info "处理完成！"
    echo "统计信息:"
    echo "  总文件数: $total_files"
    echo -e "  ${GREEN}成功: $success_count${NC}"
    echo -e "  ${RED}失败: $fail_count${NC}"
    echo -e "  ${YELLOW}跳过: $skipped_count${NC}"
    echo "=========================================="
}

# 运行主函数
main "$@"