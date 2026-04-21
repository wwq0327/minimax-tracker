# minimax-tracker v0.2.0

## 目标
在 Claude Code 状态栏显示 MiniMax 包月订阅的 5 小时用量进度条。

## 技术方案

- 通过 `mmx quota show` 命令获取实时用量（官方 CLI，数据准确）
- Claude Code 状态栏脚本读取数据并渲染进度条
- 按需抓取：仅 Claude Code 工作时自动刷新（超过3分钟未刷新则抓取）

## 文件

| 文件 | 说明 |
|------|------|
| `status-bar.sh` | 主脚本 |
| `install.sh` | 安装脚本 |
| `README.md` | 使用文档 |

## 安装

```bash
./install.sh
```

## 状态栏配置

`~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/walt/.minimax-tracker/status-bar.sh"
  }
}
```

## 进度条样式

```
MiniMax: [██░░░░░░░░░░░░░░░░░] 30% 450/1500 (2小时后重置, 0分钟前)
```

## 颜色分级

| 使用率 | 颜色 |
|--------|------|
| 0-50% | 绿色 |
| 51-80% | 黄色 |
| 81%+ | 红色 |
