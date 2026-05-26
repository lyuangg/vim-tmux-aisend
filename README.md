# vim-tmux-aisend

Send code context to AI via clipboard or tmux — perfect for pasting code into a Claude Code / AI session running in an adjacent tmux pane.

## Features

- **Copy for AI** — Visually select code, press `<leader>ay`. Formats with file path, line numbers, and syntax highlighting markers.
- **Send to tmux** — Press `<leader>at` to send directly to an adjacent tmux pane (auto-selects the largest non-current pane).
- **Manual target** — Like [tslime.vim](https://github.com/jgdavey/tslime.vim), use `:AITarget` to interactively select session/window/pane with tab completion.
- **Clipboard fallback** — If you're not in tmux or only one pane exists, falls back to system clipboard.

## Installation

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'lyuangg/vim-tmux-aisend'
" or for local development:
" Plug '~/yuan/github/vim-tmux-aisend'
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'lyuangg/vim-tmux-aisend'
```

### [Vim 8 native](https://vimhelp.org/repeat.txt.html#packages)

```bash
mkdir -p ~/.vim/pack/plugins/start
git clone https://github.com/lyuangg/vim-tmux-aisend ~/.vim/pack/plugins/start/vim-tmux-aisend
```

## Usage

| Mapping | Mode | Action |
|---------|------|--------|
| `<leader>ay` | Visual | Copy selection (with file/line info) to clipboard |
| `<leader>at` | Visual | Send selection to tmux (or clipboard fallback) |
| `<leader>at` | Normal | Send current line to tmux |
| `<leader>as` | Normal | Set tmux target interactively |

### Commands

```
:[range]CopyForAI     Copy range with context to clipboard
:[range]SendForAI     Send range to tmux (or clipboard)
:AITarget             Manually set session:window.pane
:AIClearTarget        Clear manual target, revert to auto-select
```

### Target priority

1. `g:ai_tmux_target_pane` — raw pane ID override (e.g. `'%1'`)
2. `g:ai_send_target` — manual target set via `:AITarget`
3. Auto — largest non-current tmux pane

### Configuration

```vim
" Force a specific pane (disables auto-select)
let g:ai_tmux_target_pane = '%1'

" Disable clipboard fallback when not in tmux
let g:ai_tmux_fallback_clipboard = 0

" Auto-select tallest pane during :AITarget (skip manual pane prompt)
let g:ai_tmux_autoset_pane = 1

" List all sessions/windows during :AITarget (default: current only)
let g:ai_tmux_always_current_session = 0
let g:ai_tmux_always_current_window = 0

" Disable default mappings, use <Plug> instead
let g:ai_tmux_no_mappings = 1
nmap <leader>st <Plug>SetAITarget
vmap <leader>ss <Plug>SendSelectionToAI
```

## License

DWTFYWTPL — Do What The Fuck You Want To Public License.
