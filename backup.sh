#!/bin/bash

# --- 基础配置 ---
REMOTE_NAME="od-sp-sp-efiwzyhm"
LOG_FILE="/home/hechuan/backup.log"
TEMP_DIR="/tmp"
KEEP_COUNT=2  # 网盘保留最近 2 个备份

# --- 待备份任务列表 (格式: "本地目录|网盘路径|文件前缀") ---
TASKS=(
    "/home/hechuan/openlist/data|/site-backup/openlist|openlist_data"
    "/home/hechuan/twikoo/data|/site-backup/twikoo|twikoo_data"
)

# --- 时间变量 ---
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
FILE_TIME=$(date +%Y%m%d_%H%M%S)

{
    echo "------------------------------------------------"
    echo "[$TIMESTAMP] 启动批量备份任务..."

    for TASK in "${TASKS[@]}"; do
        # 解析任务参数
        IFS='|' read -r SOURCE_DIR REMOTE_PATH FILE_PREFIX <<< "$TASK"
        
        ZIP_NAME="${FILE_PREFIX}_${FILE_TIME}.zip"
        ZIP_FULL_PATH="$TEMP_DIR/$ZIP_NAME"

        echo ">>> 开始处理: $SOURCE_DIR"

        # 1. 压缩目录
        echo "步骤 1: 正在压缩..."
        if zip -rq "$ZIP_FULL_PATH" "$SOURCE_DIR"; then
            echo "压缩成功: $ZIP_NAME"
        else
            echo "错误: $SOURCE_DIR 压缩失败，跳过此项！"
            continue
        fi

        # 2. 上传到网盘
        echo "步骤 2: 正在上传到 $REMOTE_NAME:$REMOTE_PATH ..."
        # 使用 --stats-one-line 确保只输出一行统计结果
		if rclone copy "$ZIP_FULL_PATH" "$REMOTE_NAME:$REMOTE_PATH" --stats-one-line --stats 1s --stats-log-level NOTICE; then
            echo "上传成功！"
        else
            echo "错误: 上传失败！"
            rm -f "$ZIP_FULL_PATH"
            continue
        fi

        # 3. 清理本地临时压缩包
        rm -f "$ZIP_FULL_PATH"
        echo "步骤 3: 已清理本地临时压缩包。"

        # 4. 保留最近备份
        echo "步骤 4: 正在清理旧备份 (保留 $KEEP_COUNT 个)..."
        OLD_FILES=$(rclone lsf "$REMOTE_NAME:$REMOTE_PATH" --files-only | sort | head -n -"$KEEP_COUNT")
        
        if [ -n "$OLD_FILES" ]; then
            while read -r file; do
                [ -n "$file" ] && rclone deletefile "$REMOTE_NAME:$REMOTE_PATH/$file" && echo "已删除旧备份: $file"
            done <<< "$OLD_FILES"
        else
            echo "无需清理。"
        fi
        echo ">>> $SOURCE_DIR 备份完成。"
        echo ""
    done

    echo "[$TIMESTAMP] 所有备份任务全部完成！"
} 2>&1 | tee -a "$LOG_FILE"
