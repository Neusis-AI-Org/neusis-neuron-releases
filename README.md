# neusis-neuron-mcp — releases

Public binary release mirror for **neusis-neuron-mcp**, a Neusis fork of the
GitHub MCP Server that gives the `neusis-code` agent read-only access to a
single project-brain knowledge-base (KB) repository.

The server source is maintained privately; this repository hosts the published
binaries (GitHub Releases) and the install scripts only.

## Install

**macOS / Linux**

```sh
curl -fsSL https://neusis-ai-org.github.io/neusis-neuron-releases/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://neusis-ai-org.github.io/neusis-neuron-releases/install.ps1 | iex
```

The installer downloads the binary for your platform, installs it to
`~/.local/bin` (override with `INSTALL_DIR`), and upgrades an existing install
in place when re-run. Pin a version with the `VERSION` environment variable.

## Configure neusis-code

Register the server under the `mcp` key in `neusiscode.json`:

```jsonc
{
  "mcp": {
    "neusis-neuron": {
      "type": "local",
      "command": ["neusis-neuron-mcp", "stdio", "--kb-repo", "OWNER/REPO"],
      "environment": { "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token" },
      "enabled": true
    }
  }
}
```

- `--kb-repo OWNER/REPO` — **required.** The single KB repository the server is
  bound to. Every tool operates only on this repo.
- `GITHUB_PERSONAL_ACCESS_TOKEN` — a fine-grained token with `Contents: Read` on
  that KB repository: <https://github.com/settings/personal-access-tokens/new>.

The server exposes three read-only tools — `get_file_contents`,
`get_repository_tree`, `search_code` — all scoped to the bound repository.
