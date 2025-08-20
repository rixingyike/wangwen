#!/bin/bash
# 文件名: generate_summary.sh
# 功能: 自动生成GitBook的SUMMARY.md文件，包含所有Markdown文件的链接
# 特点: 
# 1. 自动为目录和文件生成正确的相对路径链接
# 2. 按数字前缀排序文件
# 3. 自动创建缺失的README.md文件
# 4. 忽略指定的目录和文件

# 配置选项
IGNORE_DIRS=("_book" "assets" "_layouts" "node_modules")  # 忽略的目录
IGNORE_FILES=("SUMMARY.md" "README.md")  # 忽略的文件
BOOK_TITLE="目录" # 自定义标题

# 生成初始文件
echo "# $BOOK_TITLE" > SUMMARY.md
echo "" >> SUMMARY.md
# echo "* [首页](README.md)" >> SUMMARY.md

# 递归遍历函数
generate_tree() {
  local dir="$1"
  local indent="$2"
  
  # 检查当前目录是否有README.md，如果没有则创建
  if [ ! -f "$dir/README.md" ]; then
    local dir_name=$(basename "$dir")
    echo "# $dir_name" > "$dir/README.md"
    echo "" >> "$dir/README.md"
    echo "此目录包含 $dir_name 相关内容。" >> "$dir/README.md"
  fi
  
  # 创建临时数组存储目录和文件
  declare -a dirs=()
  declare -a files=()
  
  for item in "$dir"/*; do
    # 跳过忽略项
    base_item=$(basename "$item")
    [[ " ${IGNORE_DIRS[@]} " =~ " $base_item " ]] && continue
    [[ " ${IGNORE_FILES[@]} " =~ " $base_item " ]] && continue
    
    if [ -d "$item" ]; then
      # 收集目录
      dirs+=("$item")
    elif [ -f "$item" ] && [[ "$item" == *.md ]] && [ "$(basename "$item")" != "README.md" ]; then
      # 收集Markdown文件
      files+=("$item")
    fi
  done
  
  # 处理目录（目录不排序）
  for item in "${dirs[@]}"; do
    base_item=$(basename "$item")
    # 生成相对路径的链接
    rel_path="${item#./}"
    echo "${indent}* [${base_item}](${rel_path}/README.md)" >> SUMMARY.md
    generate_tree "$item" "$indent  "
  done
  
  # 处理文件（按数字排序）
  # 创建关联数组存储文件和其排序键
  declare -A file_keys
  for item in "${files[@]}"; do
    title=$(basename "$item" .md)
    # 提取文件名开头的数字作为排序键
    sort_key=$(echo "$title" | grep -o '^[0-9]*' || echo "999999")
    # 如果没有数字，使用一个大数字作为默认值
    if [ -z "$sort_key" ]; then
      sort_key="999999"
    fi
    # 存储文件路径和排序键的关系
    file_keys["$item"]=$sort_key
  done
  
  # 按数字排序并输出文件，生成正确的链接
  for item in $(for k in "${!file_keys[@]}"; do echo "${file_keys[$k]} $k"; done | sort -n | cut -d' ' -f2-); do
    title=$(basename "$item" .md)
    # 生成相对路径的链接
    rel_path="${item#./}"
    echo "${indent}* [${title}](${rel_path})" >> SUMMARY.md
  done
}

# 从根目录开始生成
generate_tree "." ""
cp -f SUMMARY.md README.md

echo "SUMMARY.md 已生成！"