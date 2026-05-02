# MiniMax/DeepSeek Tracker v0.3.0

## 目标
在 Claude Code 状态栏显示 MiniMax 用量或 DeepSeek 余额。

## 技术方案

- MiniMax: 通过 `mmx quota show` 命令获取实时用量（官方 CLI）
- DeepSeek: 通过 `curl` 调用 `/user/balance` API 获取余额
- 根据当前使用的模型自动切换显示：模型名含 `deepseek` 显示 DeepSeek，含 `minimax` 显示 MiniMax
- 两个 key 都配但模型不匹配时，优先显示 DeepSeek
- DeepSeek 日度差额：与最近一个非今天的余额记录比较，显示消耗(↓)或充值(↑)
- 按需抓取：仅 Claude Code 工作时自动刷新（超过3分钟未刷新则抓取）

## 文件

| 文件 | 说明 |
|------|------|
| `status-bar.sh` | 主脚本 |
| `install.sh` | 安装脚本 |
| `README.md` | 使用文档 |

## 数据文件（~/.minimax-tracker/）

| 文件 | 说明 |
|------|------|
| `usage.json` | MiniMax 用量缓存 |
| `ds_balance.json` | DeepSeek 余额缓存 |
| `ds_daily.json` | DeepSeek 日度余额记录（保留最近7天） |

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

## 环境变量

| 变量 | 用途 |
|------|------|
| `MINIMAX_API_KEY` | MiniMax API key |
| `DEEPSEEK_API_KEY` | DeepSeek API key |

至少设置一个。

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
