#!/usr/bin/env bash

# Claude Code Model Selector & Launcher
# Picks model backend, sets env vars, launches `claude` with --dangerously-skip-permissions

set -euo pipefail

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_FILE="$HOME/.claude_selector_keys.env"

# Load saved keys
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

# Default YOLO on
CLAUDE_YOLO_MODE="${CLAUDE_YOLO_MODE:-true}"

# Resolve the REAL claude binary (skip shell functions/aliases)
CLAUDE_BIN="$(command -v claude 2>/dev/null || true)"
if [ -z "$CLAUDE_BIN" ]; then
    # Fallback: search common paths
    for p in /usr/local/bin/claude /opt/homebrew/bin/claude "$HOME/.npm/bin/claude" "$HOME/.antigravity-ide/antigravity-ide/bin/claude"; do
        if [ -x "$p" ]; then CLAUDE_BIN="$p"; break; fi
    done
fi
if [ -z "$CLAUDE_BIN" ]; then
    echo -e "${RED}Error: 'claude' binary not found in PATH.${NC}"
    exit 1
fi

save_key() {
    local key_name="$1" key_value="$2"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    if [ -f "$CONFIG_FILE" ]; then
        grep -v "^export ${key_name}=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" || true
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
    echo "export ${key_name}=\"${key_value}\"" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
}

get_key_or_prompt() {
    local var_name="$1" prompt_msg="$2"
    local current_val="${!var_name:-}"
    if [ -z "$current_val" ]; then
        echo -e "${YELLOW}🔑 Enter ${prompt_msg}:${NC}"
        read -r input_val
        if [ -z "$input_val" ]; then
            echo -e "${RED}⚠️  Key cannot be empty.${NC}"
            exit 1
        fi
        save_key "$var_name" "$input_val"
        eval "${var_name}=\"${input_val}\""
    fi
}

# Reset per-session env
unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN 2>/dev/null || true

# ── Main loop ──
while true; do
    clear
    echo -e "${BOLD}${CYAN}====================================================${NC}"
    echo -e "${BOLD}${MAGENTA}             CLAUDE CODE MODEL LAUNCHER            ${NC}"
    echo -e "${BOLD}${CYAN}====================================================${NC}"

    if [ "$CLAUDE_YOLO_MODE" = "true" ]; then
        echo -e "  🔥 YOLO Mode (Skip Permissions): ${BOLD}${GREEN}ENABLED${NC}"
    else
        echo -e "  🔒 YOLO Mode (Skip Permissions): ${BOLD}${RED}DISABLED${NC}"
    fi

    echo -e "${BOLD}${CYAN}====================================================${NC}"
    echo -e ""
    echo -e "  ${BOLD}${GREEN} 1)${NC} 🌟 Claude Opus (Max Subscription)"
    echo -e "  ${BOLD}${GREEN} 2)${NC} 🧪 GLM 5.2 (api.z.ai Proxy)"
    echo -e "  ${BOLD}${GREEN} 3)${NC} 🌟 Claude Sonnet (API Key)"
    echo -e "  ${BOLD}${GREEN} 4)${NC} 🚀 Kimi 2.6 (Direct Moonshot AI)"
    echo -e "  ${BOLD}${GREEN} 5)${NC} 🌌 Kimi 2.6 (OpenRouter)"
    echo -e "  ${BOLD}${GREEN} 6)${NC} 🤖 DeepSeek V3 (OpenRouter)"
    echo -e "  ${BOLD}${GREEN} 7)${NC} 🧠 DeepSeek R1 (OpenRouter)"
    echo -e "  ${BOLD}${GREEN} 8)${NC} ♊ Gemini 2.5 Pro (OpenRouter)"
    echo -e "  ${BOLD}${GREEN} 9)${NC} ⚡ Gemini 2.5 Flash (OpenRouter)"
    echo -e "  ${BOLD}${GREEN}10)${NC} 💻 OpenAI Codex / GPT-5 (OpenRouter)"
    echo -e "  ${BOLD}${GREEN}11)${NC} ⚙️  Custom Endpoint"
    echo -e "  ${BOLD}${YELLOW} t)${NC} 🔄 Toggle YOLO Mode"
    echo -e "  ${BOLD}${RED} x)${NC} ❌ Exit"
    echo -e ""
    echo -e "${BOLD}${CYAN}====================================================${NC}"
    echo -n "Select option: "
    read -r opt

    # Build launch args
    LAUNCH_ARGS=()
    if [ "$CLAUDE_YOLO_MODE" = "true" ]; then
        LAUNCH_ARGS+=("--dangerously-skip-permissions")
    fi

    case "$opt" in
        t|T)
            if [ "$CLAUDE_YOLO_MODE" = "true" ]; then
                CLAUDE_YOLO_MODE="false"
            else
                CLAUDE_YOLO_MODE="true"
            fi
            save_key "CLAUDE_YOLO_MODE" "$CLAUDE_YOLO_MODE"
            continue
            ;;
        1)
            # Force subscription login — strip any proxy env vars from settings.json
            # so Claude Code uses the Max plan OAuth login instead of API billing
            unset ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN 2>/dev/null || true
            SETTINGS_FILE="$HOME/.claude/settings.json"
            SETTINGS_BAK="$HOME/.claude/settings.json.bak-$$"

            # Back up current settings
            cp "$SETTINGS_FILE" "$SETTINGS_BAK"

            # Remove ANTHROPIC env vars from settings so Max subscription is used
            jq 'del(.env.ANTHROPIC_BASE_URL, .env.ANTHROPIC_AUTH_TOKEN, .env.ANTHROPIC_API_KEY)' \
                "$SETTINGS_BAK" > "$SETTINGS_FILE"

            # Restore settings on exit (any exit: normal, Ctrl-C, kill)
            trap 'cp "$SETTINGS_BAK" "$SETTINGS_FILE" && rm -f "$SETTINGS_BAK" 2>/dev/null; trap - EXIT INT TERM' EXIT INT TERM

            echo -e "${GREEN}Launching Claude (Max Subscription)...${NC}"
            "$CLAUDE_BIN" "${LAUNCH_ARGS[@]}" "$@"
            EXIT_CODE=$?

            # Restore settings
            cp "$SETTINGS_BAK" "$SETTINGS_FILE"
            rm -f "$SETTINGS_BAK" 2>/dev/null
            trap - EXIT INT TERM
            exit $EXIT_CODE
            ;;
        2)
            get_key_or_prompt "ZAI_AUTH_TOKEN" "api.z.ai Auth Token"
            SETTINGS_FILE="$HOME/.claude/settings.json"
            SETTINGS_BAK="$HOME/.claude/settings.json.bak-$$"

            # Back up current settings
            cp "$SETTINGS_FILE" "$SETTINGS_BAK"

            # Inject GLM env vars + context window override into settings.json
            jq --arg token "$ZAI_AUTH_TOKEN" '
                .env.ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic" |
                .env.ANTHROPIC_AUTH_TOKEN = $token |
                .env.ANTHROPIC_API_KEY = "" |
                .env.CLAUDE_CODE_AUTO_COMPACT_WINDOW = "1000000"
            ' "$SETTINGS_BAK" > "$SETTINGS_FILE"

            # Restore settings on exit (any exit: normal, Ctrl-C, kill)
            trap 'cp "$SETTINGS_BAK" "$SETTINGS_FILE" && rm -f "$SETTINGS_BAK" 2>/dev/null; trap - EXIT INT TERM' EXIT INT TERM

            echo -e "${GREEN}Launching GLM 5.2 (api.z.ai) — 1M context...${NC}"
            "$CLAUDE_BIN" --model "glm-5.2[1m]" "${LAUNCH_ARGS[@]}" "$@"
            EXIT_CODE=$?

            # Restore settings
            cp "$SETTINGS_BAK" "$SETTINGS_FILE"
            rm -f "$SETTINGS_BAK" 2>/dev/null
            trap - EXIT INT TERM
            exit $EXIT_CODE
            ;;
        3)
            get_key_or_prompt "ANTHROPIC_API_KEY" "Anthropic API Key (sk-...)"
            export ANTHROPIC_API_KEY
            echo -e "${GREEN}Launching Claude (API Key)...${NC}"
            exec "$CLAUDE_BIN" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        4)
            get_key_or_prompt "MOONSHOT_API_KEY" "Moonshot API Key (sk-...)"
            export ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropic"
            export ANTHROPIC_API_KEY="$MOONSHOT_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$MOONSHOT_API_KEY"
            echo -e "${GREEN}Launching Kimi 2.6 (direct)...${NC}"
            exec "$CLAUDE_BIN" --model "kimi-k2.6" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        5)
            get_key_or_prompt "OPENROUTER_API_KEY" "OpenRouter API Key (sk-or-...)"
            export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
            export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
            echo -e "${GREEN}Launching Kimi 2.6 (OpenRouter)...${NC}"
            exec "$CLAUDE_BIN" --model "moonshotai/kimi-k2.6" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        6)
            get_key_or_prompt "OPENROUTER_API_KEY" "OpenRouter API Key (sk-or-...)"
            export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
            export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
            echo -e "${GREEN}Launching DeepSeek V3 (OpenRouter)...${NC}"
            exec "$CLAUDE_BIN" --model "deepseek/deepseek-chat" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        7)
            get_key_or_prompt "OPENROUTER_API_KEY" "OpenRouter API Key (sk-or-...)"
            export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
            export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
            echo -e "${GREEN}Launching DeepSeek R1 (OpenRouter)...${NC}"
            exec "$CLAUDE_BIN" --model "deepseek/deepseek-r1" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        8)
            get_key_or_prompt "OPENROUTER_API_KEY" "OpenRouter API Key (sk-or-...)"
            export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
            export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
            echo -e "${GREEN}Launching Gemini 2.5 Pro (OpenRouter)...${NC}"
            exec "$CLAUDE_BIN" --model "google/gemini-2.5-pro" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        9)
            get_key_or_prompt "OPENROUTER_API_KEY" "OpenRouter API Key (sk-or-...)"
            export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
            export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
            echo -e "${GREEN}Launching Gemini 2.5 Flash (OpenRouter)...${NC}"
            exec "$CLAUDE_BIN" --model "google/gemini-2.5-flash" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        10)
            get_key_or_prompt "OPENROUTER_API_KEY" "OpenRouter API Key (sk-or-...)"
            export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
            export ANTHROPIC_API_KEY="$OPENROUTER_API_KEY"
            export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
            echo -e "${GREEN}Launching OpenAI Codex / GPT-5 (OpenRouter)...${NC}"
            exec "$CLAUDE_BIN" --model "openai/gpt-5-codex" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        11)
            echo -e "${YELLOW}Enter Custom Base URL:${NC}"
            read -r CUSTOM_BASE_URL
            echo -e "${YELLOW}Enter Custom API/Auth Key:${NC}"
            read -r CUSTOM_KEY
            echo -e "${YELLOW}Enter Model ID:${NC}"
            read -r CUSTOM_MODEL
            export ANTHROPIC_BASE_URL="$CUSTOM_BASE_URL"
            export ANTHROPIC_API_KEY="$CUSTOM_KEY"
            export ANTHROPIC_AUTH_TOKEN="$CUSTOM_KEY"
            echo -e "${GREEN}Launching $CUSTOM_MODEL...${NC}"
            exec "$CLAUDE_BIN" --model "$CUSTOM_MODEL" "${LAUNCH_ARGS[@]}" "$@"
            ;;
        x|X)
            echo -e "${YELLOW}Bye.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Try again.${NC}"
            sleep 1
            ;;
    esac
done
