# zsh-nvm-auto-use

An [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) plugin that automatically
switches Node.js versions using the closest `.nvmrc` when you change directories.

## Requirements

- Zsh with Oh My Zsh.
- [nvm](https://github.com/nvm-sh/nvm) loaded before the first shell prompt.
- The requested Node.js version already installed through nvm.

This plugin does not load nvm or install Node.js.

## Installation

1. Clone the plugin into your Oh My Zsh custom plugins directory:

   ```zsh
   git clone git@github.com:martvdmoosdijk/zsh-nvm-auto-use.git \
     "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-nvm-auto-use"
   ```

2. Add `zsh-nvm-auto-use` to the existing `plugins` list in your `.zshrc`.
   Keep your other plugins; for example:

   ```zsh
   plugins=(git zsh-nvm-auto-use)
   ```

3. Open a new terminal, or reload your shell configuration:

   ```zsh
   source ~/.zshrc
   ```

## Usage

Put a version request on a single line in your project's `.nvmrc`, for example:

```text
24
```

Both `24` and `v24` select the newest installed Node 24 version. To select an
exact version, use a full version such as `24.9.0`. nvm aliases such as `lts/*`
also work.

The plugin checks once before the first prompt and again whenever you change
directories. It searches the current folder, then its parents up to the
filesystem root. The closest `.nvmrc` wins, so a subfolder can override its
parent's version. If no file is found, Node stays unchanged.

## Configuration

Set these optional variables in your `.zshrc` **before Oh My Zsh loads the plugin**:

```zsh
NVM_AUTO_USE_DEBUG=0
NVM_AUTO_USE_NOTIFY=1
```

| Setting | Default | Behavior when set to `1` |
| --- | --- | --- |
| `NVM_AUTO_USE_DEBUG` | `0` | Show detailed logs, including versions, search depth, and total time. |
| `NVM_AUTO_USE_NOTIFY` | `1` | Announce actual version changes when debugging is off. |

In debug logs, search depth `0` means the current folder, `1` means its parent,
and so on.

## Caching

After a successful switch, the plugin remembers the request, `NVM_BIN` (the
selected Node bin directory), and `PATH`. If they are unchanged, it skips
`nvm use`. Numeric requests such as `24` and `v24` share the same cache entry.
Edits to the requested version and manual changes to the Node environment
trigger a new check. Failed switches are not cached and are retried on the next
directory change.

Aliases and partial versions are resolved when the cache is refreshed, not on
every directory change. After changing an alias or installing a newer matching
version, run `nvm use` manually or start a new shell to select it.
