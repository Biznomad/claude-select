# 🚀 Claude Code Model Selector

A colorful CLI launcher for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that lets you switch between multiple AI model backends with a single menu.

![Claude Code Model Launcher](https://img.shields.io/badge/Claude_Code-Model_Launcher-blueviolet?style=for-the-badge)

## Features

- **🌟 Claude Opus** — Max Subscription (OAuth login, no API key needed)
- **🌟 Claude Sonnet** — API Key billing
- **🧪 GLM 5.2** — via api.z.ai proxy
- **🚀 Kimi 2.6** — Direct Moonshot AI or OpenRouter
- **🤖 DeepSeek V3 / R1** — via OpenRouter
- **♊ Gemini 2.5 Pro / Flash** — via OpenRouter
- **💻 OpenAI Codex / GPT-5** — via OpenRouter
- **⚙️ Custom Endpoint** — any Anthropic-compatible API
- **🔥 YOLO Mode** — toggle `--dangerously-skip-permissions` on/off
- **🔑 Key Management** — API keys are prompted once, then saved locally

## Installation

```bash
# Clone the repo
git clone https://github.com/biznomad/claude-select.git
cd claude-select

# Make executable
chmod +x claude-select.sh

# Option A: Add an alias to your shell
echo 'alias claude="/path/to/claude-select.sh"' >> ~/.zshrc

# Option B: Symlink into your PATH
ln -s "$(pwd)/claude-select.sh" /usr/local/bin/claude-select
```

## Usage

```bash
# Launch the selector
./claude-select.sh

# Or if aliased
claude
```

Select a model by number, and the script handles all environment variable configuration and launches Claude Code with the correct backend.

## How It Works

- **Max Subscription (Option 1):** Temporarily strips any proxy env vars from `~/.claude/settings.json` so Claude Code uses your Anthropic Max plan OAuth login. Settings are automatically restored on exit.
- **Proxy Models (GLM, Kimi, etc.):** Sets `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY`, and `ANTHROPIC_AUTH_TOKEN` to route traffic through the appropriate proxy.
- **OpenRouter Models:** Routes through `openrouter.ai/api` with your OpenRouter API key.
- **YOLO Mode:** Appends `--dangerously-skip-permissions` to skip Claude Code's permission prompts.

## Key Storage

API keys are saved to `~/.claude_selector_keys.env` (chmod 600) on first use. This file is never committed to git.

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` binary in PATH)
- `jq` (for JSON manipulation of settings.json)
- `bash` 4.0+

## License

MIT
