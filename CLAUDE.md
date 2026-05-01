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
