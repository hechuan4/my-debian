#!/bin/bash

# --- 基础配置 ---
SOURCE_DIR="/home/hechuan/openlist/data"
REMOTE_NAME="od-sp-sp-efiwzyhm"
REMOTE_PATH="/site-backup/openlist"
LOG_FILE="/home/hechuan/backup.log"
TEMP_DIR="/tmp"
KEEP_COUNT=2  # 网盘保留最近 2 个备份

# --- 时间变量 ---
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
FILE_TIME=$(date +%Y%m%d_%H%M%S)
ZIP_NAME="openlist_data_${FILE_TIME}.zip"
ZIP_FULL_PATH="$TEMP_DIR/$ZIP_NAME"

{
    echo "------------------------------------------------"
    echo "[$TIMESTAMP] 启动备份任务..."

    # 1. 压缩目录
    echo "步骤 1: 正在压缩目录 $SOURCE_DIR ..."
    if zip -rq "$ZIP_FULL_PATH" "$SOURCE_DIR"; then
        echo "压缩成功: $ZIP_NAME"
    else
        echo "错误: 压缩失败！"
        exit 1
    fi

    # 2. 上传到网盘
    echo "步骤 2: 正在上传到网盘 $REMOTE_NAME:$REMOTE_PATH ..."
    if rclone copy -P "$ZIP_FULL_PATH" "$REMOTE_NAME:$REMOTE_PATH"; then
        echo "上传成功！"
    else
        echo "错误: 上传失败！"
        rm -f "$ZIP_FULL_PATH"
        exit 1
    fi

    # 3. 清理本地临时压缩包
    rm -f "$ZIP_FULL_PATH"
    echo "步骤 3: 已清理本地临时压缩包。"

    # 4. 保留最近 2 个备份，删除其余旧文件
    echo "步骤 4: 正在清理网盘旧备份，仅保留最近 $KEEP_COUNT 个文件..."
    
    # 逻辑：列出所有文件，按名称排序（名称带日期，排序等同于时间排序），去掉最后 2 个，剩下的就是旧文件
    OLD_FILES=$(rclone lsf "$REMOTE_NAME:$REMOTE_PATH" --files-only | sort | head -n -"$KEEP_COUNT")
    
    if [ -n "$OLD_FILES" ]; then
        echo "发现旧备份，准备删除..."
        echo "$OLD_FILES" | while read -r file; do
            if [ -n "$file" ]; then
                rclone deletefile "$REMOTE_NAME:$REMOTE_PATH/$file"
                echo "已删除旧备份: $file"
            fi
        done
        echo "网盘清理完成。"
    else
        echo "网盘文件不足 $KEEP_COUNT 个，无需清理。"
    fi

    echo "[$TIMESTAMP] 备份任务全部完成！"
} 2>&1 | tee -a "$LOG_FILE"
