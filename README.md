# MiniMax Tracker v0.1.0

在 Claude Code 状态栏显示 MiniMax 包月订阅的 5 小时用量进度条。

[English](README_en.md) | [中文](README.md)

## 背景

MiniMax 是包月订阅，每月有 5 小时用量额度。平时需要打开网页刷新查看消耗情况，操作繁琐。

在 Claude Code 工作时直接看到用量进度条更方便。这个脚本用 vibe coding 方式完成——全程只描述需求，没有手动写一行代码。

## 功能

- 实时显示用量进度条
- 颜色分级（50%以下绿色，80%以下黄色，80%以上红色）
- 按需抓取（仅 Claude Code 工作时刷新）
- 使用官方 `mmx` CLI 获取数据，数据准确

## 依赖

- `mmx-cli` (npm install -g mmx-cli)
- `jq`
- 环境变量 `MINIMAX_API_KEY`

## 安装

### 1. 设置环境变量

```bash
export MINIMAX_API_KEY="sk-cp-你的Key"
```

添加到 `~/.zshrc` 或 `~/.bashrc` 使其永久生效：

```bash
echo 'export MINIMAX_API_KEY="sk-cp-你的Key"' >> ~/.zshrc
```

### 2. 运行安装脚本

```bash
./install.sh
```

### 3. 重启 Claude Code

## 配置说明

- API Key 通过环境变量 `MINIMAX_API_KEY` 读取（不写在代码里）
- 脚本保存在 `~/.minimax-tracker/status-bar.sh`
- 数据缓存在 `~/.minimax-tracker/usage.json`

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

## 卸载

1. 删除 `~/.claude/settings.json` 中的 `statusLine` 配置
2. 删除 `~/.minimax-tracker/` 目录
