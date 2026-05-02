# MiniMax/DeepSeek Tracker v0.3.0

在 Claude Code 状态栏显示 MiniMax 用量或 DeepSeek 余额。

[English](README_en.md) | [中文](README.md)

## 背景

在用 Claude Code 写代码，每次查模型用量都要切到网页后台刷新，繁琐。状态栏显示一眼就能看到，不用中断。

- MiniMax 是包月订阅，每月 5 小时配额
- DeepSeek 是按量计费，余额 ¥

根据当前使用的模型自动切换显示哪个服务的数据。

## 功能

- MiniMax 用量进度条 + 百分比 + 状态分级
- DeepSeek 余额显示 + 日度差额（与头天最后一次余额比较）
- 根据当前模型自动切换显示（模型名含 deepseek 显示 DeepSeek，含 minimax 显示 MiniMax）
- 按需抓取（仅 Claude Code 工作时刷新，超过 3 分钟重新获取）
- 用官方 API 获取数据（MiniMax 通过 `mmx` CLI，DeepSeek 通过 `/user/balance` API）

## 依赖

- `mmx-cli`（仅 MiniMax 需要）
- `jq`
- 至少设置 `MINIMAX_API_KEY` 或 `DEEPSEEK_API_KEY` 其中一个

## 安装

### 1. 设置环境变量

```bash
# MiniMax
export MINIMAX_API_KEY="sk-cp-你的Key"

# DeepSeek
export DEEPSEEK_API_KEY="sk-你的Key"
```

添加到 `~/.zshrc` 或 `~/.bashrc` 使其永久生效。

### 2. 运行安装脚本

```bash
./install.sh
```

### 3. 重启 Claude Code

## 显示样式

```
# MiniMax（当前模型为 MiniMax 时）
MiniMax: [████░░░░] 30% LOW 450/1500 (50分钟后重置) (3分钟前)

# DeepSeek（当前模型为 DeepSeek 时）
DeepSeek: ¥121.50 (3分钟前)

# DeepSeek 带日度差额
DeepSeek: ¥120.38 (↓¥1.62) (3分钟前)   # 余额减少（消耗）
DeepSeek: ¥130.00 (↑¥10.00) (3分钟前)  # 余额增加（充值）
```

## MiniMax 状态分级

| 使用率 | 状态 |
|--------|------|
| 0-50% | LOW |
| 51-80% | MED |
| 81%+ | HIGH |

## DeepSeek 日度差额

- 每次抓取余额后，按日期记录到 `~/.minimax-tracker/ds_daily.json`，保留最近 7 天
- 显示时取最近一个非今天的日期的余额，与当前余额算差
- 余额减少显示 `↓¥x.xx`，增加显示 `↑¥x.xx`，无变化或无历史不显示

## 配置说明

- MiniMax API Key 通过环境变量 `MINIMAX_API_KEY` 读取
- DeepSeek API Key 通过环境变量 `DEEPSEEK_API_KEY` 读取
- 脚本保存在 `~/.minimax-tracker/status-bar.sh`
- MiniMax 数据缓存在 `~/.minimax-tracker/usage.json`
- DeepSeek 数据缓存在 `~/.minimax-tracker/ds_balance.json`
- DeepSeek 日度记录保存在 `~/.minimax-tracker/ds_daily.json`

## 环境变量

| 变量 | 用途 |
|------|------|
| `MINIMAX_API_KEY` | MiniMax API key |
| `DEEPSEEK_API_KEY` | DeepSeek API key |

至少设置一个。

## 卸载

1. 删除 `~/.claude/settings.json` 中的 `statusLine` 配置
2. 删除 `~/.minimax-tracker/` 目录
