FROM nvidia/cuda:12.6.1-cudnn-devel-ubuntu24.04

# Prevent interactive prompts
ARG DEBIAN_FRONTEND=noninteractive

# 1. ENVS
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    NPM_CONFIG_PREFIX=/usr/local

# 2. SYSTEM TOOLS
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    # C/C++ toolchain
    build-essential \
    # Build tools
    pkg-config \
    libssl-dev \
    openssh-client \
    cmake \
    ninja-build \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Protobuf
    protobuf-compiler \
    libprotobuf-dev \
    # PostgreSQL
    postgresql \
    postgresql-contrib \
    postgresql-client \
    libpq-dev \
    # Utilities
    curl \
    wget \
    git \
    unzip \
    zip \
    duf \
    btop \
    nvtop \
    vim \
    fish \
    fzf \
    direnv \
    sqlite3 \
    libsqlite3-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (official repo)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# 3. DUCKDB CLI
RUN curl -fsSL https://github.com/duckdb/duckdb/releases/download/v1.2.2/duckdb_cli-linux-amd64.zip -o /tmp/duckdb.zip \
    && unzip -q /tmp/duckdb.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/duckdb \
    && rm /tmp/duckdb.zip

# 4. GO (latest stable)
ENV GOROOT=/usr/local/go \
    GOPATH=/root/go \
    PATH=/usr/local/go/bin:/root/go/bin:$PATH
RUN curl -fsSL https://go.dev/dl/go1.23.4.linux-amd64.tar.gz | tar -C /usr/local -xzf - \
    && go install golang.org/x/tools/gopls@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest \
    && go install honnef.co/go/tools/cmd/staticcheck@latest

# 5. NODE.JS (22 LTS via official tarball)
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -fsSL https://nodejs.org/dist/v22.12.0/node-v22.12.0-linux-x64.tar.xz | tar -xJf - -C /usr/local --transform='s|^node-v22.12.0-linux-x64|node|' \
    && npm config set fund false \
    && npm config set update-notifier false

# 5a. BUN (Fast JavaScript runtime & toolkit)
ENV BUN_INSTALL=/usr/local/bun \
    PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash -s -- -y \
    && mv /root/.bun /usr/local/bun

# 5b. SVELTE (Frontend framework)
RUN npm install -g @sveltejs/kit svelte create-svelte vite

# 6. UV
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# 7. RUST TOOLCHAIN
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal \
    && rustup component add rustfmt clippy rust-analyzer

# 8. RUST TOOLS (COMPILED)
RUN cargo install sccache
ENV RUSTC_WRAPPER=sccache

# install dog with the fork fixed openssl version in ubuntu 24.04
RUN cargo install --locked --git https://github.com/5731la/dog --branch fixopensslversion dog

# compile others
RUN cargo install --locked \
    ripgrep \
    fd-find \
    bat \
    eza \
    git-delta \
    tokei \
    hyperfine \
    drill \
    maturin \
    zoxide \
    starship \
    du-dust \
    zellij \
    just \
    gitui \
    procs \
    jql \
    bottom \
    tealdeer \
    sd \
    grex \
    atuin \
    && rm -rf /usr/local/cargo/registry

# 9. AI CODE AGENTS
# Claude Code (Anthropic) - requires ANTHROPIC_API_KEY
RUN npm install -g @anthropic-ai/claude-code

# Codex CLI (OpenAI) - requires OPENAI_API_KEY
RUN npm install -g @openai/codex

# Gemini CLI (Google) - requires GEMINI_API_KEY or Google Cloud auth
RUN npm install -g @google/gemini-cli

# 10. SET FISH AS DEFAULT SHELL
RUN chsh -s /usr/bin/fish root

# 11. FISH CONFIG (With Dashboard)
RUN mkdir -p /root/.config/fish

RUN echo 'if status is-interactive' > /root/.config/fish/config.fish \
    # --- 1. SETTINGS & ENV ---
    && echo '    set -gx RUSTC_WRAPPER sccache' >> /root/.config/fish/config.fish \
    # --- 2. THE DASHBOARD GREETING ---
    && echo '    function fish_greeting' >> /root/.config/fish/config.fish \
    && echo '        set_color brgreen; echo "🚀 Dev Container Ready!"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "═══════════════════════════════════════════════════════════════════"' >> /root/.config/fish/config.fish \
    && echo '        set_color brwhite; echo "🌐 LANGUAGES"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   C/C++      gcc, g++, cmake             CUDA       nvcc (12.6)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   Python     python3, uv                 Go         go (1.23), gopls"' >> /root/.config/fish/config.fish \
    && echo '        echo "   Rust       cargo, rustc, rust-analyzer Node.js    node (22), npm"' >> /root/.config/fish/config.fish \
    && echo '        echo "   Bun        bun (runtime & toolkit)     JavaScript TypeScript, JSX"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brwhite; echo "🗄️  DATABASES"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   sqlite3    Embedded SQL (OLTP)         duckdb     Embedded SQL (OLAP)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   postgres   PostgreSQL server/client    libpq      PostgreSQL C library"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brwhite; echo "🎨 FRONTEND"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   svelte     SvelteKit framework         vite       Fast build tool"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brmagenta; echo "🤖 AI CODE AGENTS"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   claude     Claude Code (Anthropic)    codex      Codex CLI (OpenAI)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   gemini     Gemini CLI (Google)        kanban     Vibe Kanban board"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "🔧 BUILD & PACKAGE"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   uv         Fast Python pkg manager    maturin    Rust→Python build"' >> /root/.config/fish/config.fish \
    && echo '        echo "   cargo      Rust package manager       sccache    Compile cache"' >> /root/.config/fish/config.fish \
    && echo '        echo "   just       Command runner (make alt)  npm/npx    Node.js packages"' >> /root/.config/fish/config.fish \
    && echo '        echo "   bun        Ultra-fast JS runtime      bunx       Execute packages"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "📂 NAVIGATION"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   cd/z       Smart jump (zoxide)        ls         List files (eza)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   find       Find files (fd)            tree       Directory tree (eza)"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "🔍 SEARCH & TEXT"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   grep       Search text (ripgrep)      fzf        Fuzzy finder"' >> /root/.config/fish/config.fish \
    && echo '        echo "   sed        Find/replace (sd)          grex       Regex generator"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "👀 VIEW & INSPECT"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   cat        View files (bat)           less       Paged view (bat)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   diff       Side-by-side (delta)       jq         JSON query (jql)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   tokei      Code statistics            dig        DNS lookup (dog)"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "📊 MONITORING"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   top        System monitor (bottom)    ps         Process list (procs)"' >> /root/.config/fish/config.fish \
    && echo '        echo "   du         Disk usage (dust)          duf        Disk free overview"' >> /root/.config/fish/config.fish \
    && echo '        echo "   nvtop      GPU monitor                btop       System dashboard"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "⚡ BENCHMARK & TEST"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   hyperfine  CLI benchmarking           drill      HTTP load testing"' >> /root/.config/fish/config.fish \
    && echo '        echo ""' >> /root/.config/fish/config.fish \
    && echo '        set_color brcyan; echo "💻 SHELL & GIT"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '        echo "   fish       Friendly shell             starship   Custom prompt"' >> /root/.config/fish/config.fish \
    && echo '        echo "   atuin      Shell history (Ctrl+R)     zellij     Terminal multiplexer"' >> /root/.config/fish/config.fish \
    && echo '        echo "   gitui      Git TUI                    gh         GitHub CLI"' >> /root/.config/fish/config.fish \
    && echo '        echo "   direnv     Per-dir env vars           tldr       Quick command help"' >> /root/.config/fish/config.fish \
    && echo '        echo "═══════════════════════════════════════════════════════════════════"' >> /root/.config/fish/config.fish \
    && echo '        set_color bryellow; echo "💡 Set API keys: ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY"; set_color normal' >> /root/.config/fish/config.fish \
    && echo '    end' >> /root/.config/fish/config.fish \
    # --- 3. ALIASES ---
    && echo '    alias grep="rg"' >> /root/.config/fish/config.fish \
    && echo '    alias find="fd"' >> /root/.config/fish/config.fish \
    && echo '    alias cat="bat --paging=never --style=plain"' >> /root/.config/fish/config.fish \
    && echo '    alias less="bat --paging=always"' >> /root/.config/fish/config.fish \
    && echo '    alias ls="eza --icons"' >> /root/.config/fish/config.fish \
    && echo '    alias ll="eza -la --git --icons"' >> /root/.config/fish/config.fish \
    && echo '    alias tree="eza --tree --icons"' >> /root/.config/fish/config.fish \
    && echo '    alias diff="delta"' >> /root/.config/fish/config.fish \
    && echo '    alias jq="jql"' >> /root/.config/fish/config.fish \
    && echo '    alias ps="procs"' >> /root/.config/fish/config.fish \
    && echo '    alias sed="sd"' >> /root/.config/fish/config.fish \
    && echo '    alias top="btm"' >> /root/.config/fish/config.fish \
    && echo '    alias dig="dog"' >> /root/.config/fish/config.fish \
    && echo '    alias du="dust"' >> /root/.config/fish/config.fish \
    && echo '    alias kanban="npx vibe-kanban"' >> /root/.config/fish/config.fish \
    # --- 4. INITIALIZATION ---
    && echo '    zoxide init fish --cmd cd | source' >> /root/.config/fish/config.fish \
    && echo '    direnv hook fish | source' >> /root/.config/fish/config.fish \
    && echo '    starship init fish | source' >> /root/.config/fish/config.fish \
    && echo '    atuin init fish | source' >> /root/.config/fish/config.fish \
    # Auto-update tldr cache
    && echo '    if not test -d ~/.cache/tealdeer' >> /root/.config/fish/config.fish \
    && echo '        tldr --update > /dev/null 2>&1 &' >> /root/.config/fish/config.fish \
    && echo '    end' >> /root/.config/fish/config.fish \
    && echo 'end' >> /root/.config/fish/config.fish

# 12. FINAL VERIFICATION
WORKDIR /root
CMD ["/usr/bin/fish"]
