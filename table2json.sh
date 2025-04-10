#!/bin/bash

# 读取文件
input_file="$1"

# 提取表头（第一行）
header=$(cat "$input_file" | sed -n '2p' | sed 's/│/ /g' | xargs -n 1)
# echo $header
# 将表头转换为数组
# IFS=$' ' read -r -a headers <<< "$header"
headers=($header)
# 初始化 JSON 数组
json_array="["
# 跳过前两行（表头和分隔线），处理数据行
while IFS= read -r line; do
    # 检查是否为分隔行
    if [[ $line == *"─"* ]]; then
        continue
    fi
    # 初始化 JSON 对象
    json="{"
    # 遍历表头，提取对应的数据
    for ((i = 0; i < ${#headers[@]}; i++)); do
        key="${headers[$i]}"
        value=$(echo "$line" | awk -F '│' -v idx=$((i + 2)) '{print $idx}' | xargs)
        json+="\"$key\": \"$value\""
        # 如果不是最后一个字段，添加逗号
        if [ $i -lt $((${#headers[@]} - 1)) ]; then
            json+=", "
        fi
    done
    # 结束 JSON 对象
    json+="}"
    # 将 JSON 对象添加到数组中
    json_array="${json_array}${json},"
    #echo $json
done < <(cat "$input_file" | tail -n +3)
#echo "$json_array"
# 删除最后一个逗号，并结束 JSON 数组
json_array=$(echo "$json_array" | sed 's/,$//')
json_array+="]"

# 输出json
echo "$json_array"
