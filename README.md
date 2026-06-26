# claude-gpt

Route **Claude Code** through a third-party OpenAI-compatible gateway (e.g. a
gpt-5.x endpoint) using [`claude-code-router`](https://github.com/musistudio/claude-code-router).

Claude Code speaks the Anthropic API. The gateway here only exposes the OpenAI
`/v1/chat/completions` protocol, so we run `ccr` locally on `127.0.0.1:3456` to
translate Anthropic ⇄ OpenAI, and point Claude Code at it via `ANTHROPIC_BASE_URL`.

## What's in here

| Path | Purpose |
|------|---------|
| [`bin/claude-real`](bin/claude-real) | Stable launcher for the real Claude Code CLI bundled with the VSCode extension (resolves the newest versioned native binary at runtime). |
| [`bin/claude-gpt5`](bin/claude-gpt5) | Convenience command: ensures `ccr` is running, injects the proxy env vars, then runs the real `claude`. |
| [`config/config.example.json`](config/config.example.json) | `ccr` config template. **No secrets** — copy to `~/.claude-code-router/config.json` and fill in your key. |
| [`systemd/ccr.service`](systemd/ccr.service) | systemd unit so `ccr` starts on boot and restarts on failure. |
| [`install.sh`](install.sh) | One-shot installer: checks Node, installs `ccr`, places launchers, scaffolds the config. Pass `--systemd` to also install + enable the boot service. |

## Requirements

- **Node.js ≥ 20.12** (`ccr` and recent Claude tooling need it). On CentOS/RHEL:
  ```bash
  curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
  dnf install -y nodejs --allowerasing   # remove old AppStream nodejs/npm first if it conflicts
  ```
- Claude Code installed (the VSCode extension's native binary is fine — `claude-real` finds it).

## Quick start

```bash
git clone git@github.com:printing-money/claude-gpt.git
cd claude-gpt
./install.sh              # add --systemd to also enable the boot service
```

Then edit `~/.claude-code-router/config.json` and set your gateway `api_key` /
`api_base_url` / `models`. Start coding:

```bash
claude-gpt5                 # interactive
claude-gpt5 -p "hello"      # one-shot print mode
```

## Run on boot (systemd)

```bash
sudo install -m 644 systemd/ccr.service /etc/systemd/system/ccr.service
sudo systemctl daemon-reload
sudo systemctl enable --now ccr.service   # start now + on every boot
systemctl status ccr                      # check it
```

`ccr start` is a foreground server, so the unit uses `Type=simple` and systemd
supervises it directly (auto-restart on failure).

## How it fits together

```
claude-gpt5  ──(env: ANTHROPIC_BASE_URL=127.0.0.1:3456)──▶  claude-real (real Claude Code CLI)
                                                                   │  Anthropic /v1/messages
                                                                   ▼
                                                       ccr (claude-code-router :3456)
                                                                   │  OpenAI /v1/chat/completions
                                                                   ▼
                                                       your gateway (gpt-5.x)
```

## Security notes

- The gateway API key lives **only** in `~/.claude-code-router/config.json`
  (chmod 600). It is never committed — `config/config.example.json` is a redacted
  template, and `.gitignore` blocks real config.
- If a key was ever pasted in plaintext (chat, logs, shell history), rotate it.
