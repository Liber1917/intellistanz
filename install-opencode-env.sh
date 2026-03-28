#!/bin/bash
#
# Auto Install & Configure Script for OpenCode Environment
# Based on current system status:
#   - Node.js: v20.20.1
#   - Bun: 1.3.11
#   - OpenCode with oh-my-opencode plugin
#   - Multiple LLM providers (Anthropic Custom, SCNet, LM Studio)
#   - 24 custom skills installed
#   - opencode-im-bridge (Feishu/QQ/Telegram/Discord/WeChat)
#   - opencove (web interface)
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  OpenCode Environment Auto-Installer  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

install_node() {
    echo -e "${YELLOW}[1/8] Installing Node.js...${NC}"
    
    if command -v node &> /dev/null; then
        echo -e "${GREEN}Node.js already installed: $(node --version)${NC}"
        return 0
    fi
    
    if command -v curl &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 
        sudo apt-get install -y nodejs
    elif command -v wget &> /dev/null; then
        wget -qO- https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Node.js installed: $(node --version)${NC}"
}

install_bun() {
    echo -e "${YELLOW}[2/8] Installing Bun...${NC}"
    
    if command -v bun &> /dev/null; then
        echo -e "${GREEN}Bun already installed: $(bun --version)${NC}"
        return 0
    fi
    
    curl -fsSL https://bun.sh/install | bash
    
    BUN_INSTALL="$HOME/.bun"
    if [ -d "$BUN_INSTALL" ]; then
        export PATH="$BUN_INSTALL/bin:$PATH"
        echo "export PATH=\"\$HOME/.bun/bin:\$PATH\"" >> ~/.bashrc
    fi
    
    echo -e "${GREEN}Bun installed: $(bun --version)${NC}"
}

install_opencode() {
    echo -e "${YELLOW}[3/8] Installing OpenCode...${NC}"
    
    if [ -f "$HOME/.opencode/bin/opencode" ]; then
        echo -e "${GREEN}OpenCode already installed${NC}"
        return 0
    fi
    
    mkdir -p "$HOME/.opencode/bin"
    mkdir -p "$HOME/.config/opencode"
    
    echo "Downloading OpenCode..."
    curl -fsSL https://opencode.ai/install.sh | bash
    
    if [ -f "$HOME/.opencode/bin/opencode" ]; then
        chmod +x "$HOME/.opencode/bin/opencode"
        echo -e "${GREEN}OpenCode installed successfully${NC}"
    else
        echo -e "${RED}Failed to install OpenCode${NC}"
        exit 1
    fi
}

configure_opencode() {
    echo -e "${YELLOW}[4/8] Configuring OpenCode...${NC}"
    
    mkdir -p "$HOME/.config/opencode"
    
    cat > "$HOME/.config/opencode/opencode.json" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "oh-my-opencode@latest"
  ],
  "provider": {
    "anthropic-custom": {
      "npm": "@ai-sdk/anthropic",
      "name": "Anthropic Custom",
      "options": {
        "baseURL": "http://www.shareapi.cloud/v1",
        "apiKey": "YOUR_API_KEY_HERE"
      },
      "models":{
        "claude-opus-4-6": { "name": "Claude Opus 4-6" },
        "claude-sonnet-4-6": { "name": "Claude Sonnet 4-6" },
        "claude-opus-4-5": { "name": "Claude Opus 4-5" },
        "claude-sonnet-4-5": { "name": "Claude Sonnet 4-5" },
        "claude-haiku-4-5": { "name": "Claude Haiku 4-5" }
      }
    },
    "scnet": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "SCNet",
      "options": {
        "baseURL": "https://api.scnet.cn/api/llm/v1",
        "apiKey": "YOUR_API_KEY_HERE"
      },
      "models": {
        "DeepSeek-V3.2": { "name": "DeepSeek V3.2" },
        "MiniMax-M2.5": { "name": "MiniMax M2.5" }
      }
    },
    "lmstudio": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio (Local)",
      "options": {
        "baseURL": "http://localhost:1234/v1",
        "apiKey": "lm-studio"
      },
      "models": {}
    }
  }
}
EOF

    cat > "$HOME/.config/opencode/oh-my-opencode.json" << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "update": true,
  "agents": {
    "hephaestus": {},
    "oracle": {},
    "librarian": {},
    "explore": {},
    "multimodal-looker": {},
    "prometheus": {},
    "metis": {},
    "momus": {},
    "atlas": {},
    "sisyphus-junior": { "default_builder_enabled": true, "replace_plan": false }
  },
  "categories": {
    "visual-engineering": {},
    "ultrabrain": {},
    "deep": {},
    "artistry": {},
    "quick": {},
    "unspecified-low": {},
    "unspecified-high": {},
    "writing": {}
  },
  "auto_update": true,
  "skills": {
    "sources": [{ "path": "/root/.claude/skills", "recursive": true, "glob": "SKILL.md" }],
    "enable": [
      "coding-standards", "tdd-workflow", "security-review", "e2e-testing",
      "verification-loop", "strategic-compact", "eval-harness", "continuous-learning",
      "search-first", "api-design", "backend-patterns", "frontend-patterns",
      "docker-patterns", "deployment-patterns", "database-migrations", "python-patterns",
      "python-testing", "django-patterns", "django-security", "django-tdd",
      "django-verification", "cpp-coding-standards", "cpp-testing"
    ]
  },
  "features": { "openclaw": false, "mcpServers": [] }
}
EOF

    echo -e "${GREEN}OpenCode configured successfully${NC}"
}

install_plugins() {
    echo -e "${YELLOW}[5/8] Installing oh-my-opencode plugin...${NC}"
    
    cd "$HOME/.config/opencode"
    
    if [ ! -f "package.json" ]; then
        echo '{}' > package.json
    fi
    
    bun add oh-my-opencode@latest
    
    echo -e "${GREEN}Plugin installed${NC}"
}

install_im_bridge() {
    echo -e "${YELLOW}[6/8] Installing opencode-im-bridge...${NC}"
    
    if bun pm ls -g 2>/dev/null | grep -q "opencode-im-bridge"; then
        echo -e "${GREEN}opencode-im-bridge already installed: $(bun pm ls -g 2>/dev/null | grep opencode-im-bridge | awk '{print $2}')${NC}"
    else
        bun add -g opencode-im-bridge
        echo -e "${GREEN}opencode-im-bridge installed${NC}"
    fi
    
    echo -e "${GREEN}Setting up opencode-im-bridge config...${NC}"
    
    BRIDGE_DIR="$HOME/opencode-im-bridge"
    mkdir -p "$BRIDGE_DIR/data"
    
    cat > "$BRIDGE_DIR/opencode-im-bridge.jsonc" << 'EOF'
{
  "feishu": {
    "appId": "${FEISHU_APP_ID}",
    "appSecret": "${FEISHU_APP_SECRET}",
    "verificationToken": "",
    "webhookPort": 3001
  },
  "qq": {
    "appId": "${QQ_APP_ID}",
    "secret": "${QQ_SECRET}",
    "sandbox": false
  },
  "telegram": {
    "botToken": "${TELEGRAM_BOT_TOKEN}"
  },
  "discord": {
    "botToken": "${DISCORD_BOT_TOKEN}"
  },
  "wechat": {
    "enabled": false,
    "sessionFile": "./data/wechat-session.json"
  },
  "defaultAgent": "build",
  "dataDir": "./data",
  "progress": {
    "debounceMs": 500,
    "maxDebounceMs": 3000
  },
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
EOF

    cat > "$BRIDGE_DIR/.env" << 'EOF'
# Feishu Configuration
FEISHU_APP_ID=YOUR_FEISHU_APP_ID
FEISHU_APP_SECRET=YOUR_FEISHU_APP_SECRET

# QQ Configuration
QQ_APP_ID=YOUR_QQ_APP_ID
QQ_SECRET=YOUR_QQ_SECRET

# Telegram Configuration
TELEGRAM_BOT_TOKEN=YOUR_TELEGRAM_BOT_TOKEN

# Discord Configuration
DISCORD_BOT_TOKEN=YOUR_DISCORD_BOT_TOKEN

# OpenCode Server
OPENCODE_SERVER_URL=http://localhost:4096
EOF

    echo -e "${GREEN}opencode-im-bridge configured at ~/opencode-im-bridge/${NC}"
    echo -e "${GREEN}  - Edit .env to add your credentials${NC}"
    echo -e "${GREEN}  - Supported: Feishu, QQ, Telegram, Discord, WeChat${NC}"
}

configure_opencove() {
    echo -e "${YELLOW}[7/8] Configuring opencove (web interface)...${NC}"
    
    echo -e "${GREEN}opencove is the web interface for OpenCode${NC}"
    echo -e "${GREEN}  - Access at: https://opencove.dev${NC}"
    echo -e "${GREEN}  - Or run locally: opencode web --port 4096${NC}"
    echo -e "${GREEN}  - Local: http://localhost:4096${NC}"
    echo ""
    echo -e "${YELLOW}For local web interface:${NC}"
    echo "  1. opencode serve"
    echo "  2. opencode web --port 4096"
    echo "  3. Browser: http://localhost:4096"
    
    echo -e "${GREEN}opencove configuration ready${NC}"
}

install_skills() {
    echo -e "${YELLOW}[8/8] Setting up skills...${NC}"
    
    mkdir -p "$HOME/.claude/skills"
    
    SKILLS=(
        "api-design" "backend-patterns" "coding-standards" "continuous-learning"
        "cpp-coding-standards" "cpp-testing" "database-migrations" "deployment-patterns"
        "django-patterns" "django-security" "django-tdd" "django-verification"
        "docker-patterns" "e2e-testing" "eval-harness" "frontend-patterns"
        "python-patterns" "python-testing" "search-first" "security-review"
        "strategic-compact" "tdd-workflow" "verification-loop"
    )
    
    for skill in "${SKILLS[@]}"; do
        skill_file="$HOME/.claude/skills/$skill/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            echo "  - $skill: not found locally"
        fi
    done
    
    echo -e "${GREEN}Skills directory ready at ~/.claude/skills/${NC}"
}

add_to_path() {
    echo -e "${YELLOW}Configuring PATH...${NC}"
    
    if ! grep -q "\.opencode/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc
    fi
    
    if [ -f "$HOME/.bun/bin" ]; then
        if ! grep -q "\.bun/bin" ~/.bashrc 2>/dev/null; then
            echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
        fi
    fi
    
    export PATH="$HOME/.opencode/bin:$HOME/.bun/bin:$PATH"
    
    echo -e "${GREEN}PATH configured${NC}"
}

verify() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}         Verification                 ${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "Node.js:           $(node --version 2>/dev/null || echo 'NOT FOUND')"
    echo -e "Bun:               $(bun --version 2>/dev/null || echo 'NOT FOUND')"
    echo -e "OpenCode:          $($HOME/.opencode/bin/opencode --version 2>/dev/null || echo 'NOT FOUND')"
    echo -e "opencode-im-bridge: $(bun pm ls -g 2>/dev/null | grep opencode-im-bridge | awk '{print $2}' || echo 'NOT FOUND')"
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Edit ~/.config/opencode/opencode.json to add your API keys"
    echo "  2. Edit ~/opencode-im-bridge/.env to add IM bridge credentials"
    echo "  3. Run: source ~/.bashrc"
    echo ""
    echo "Starting opencode-im-bridge:"
    echo "  - Terminal 1: opencode serve"
    echo "  - Terminal 2: opencode-im-bridge"
    echo ""
    echo "Starting web interface:"
    echo "  - opencode web --port 4096"
    echo "  - Browser: http://localhost:4096"
}

main() {
    install_node
    install_bun
    install_opencode
    configure_opencode
    install_plugins
    install_im_bridge
    configure_opencove
    install_skills
    add_to_path
    verify
}

main "$@"
