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

### Target resolution（按 `<leader>at` 发送时的查找顺序）

1. `g:ai_tmux_target_pane` — 硬编码 pane ID 覆盖（如 `'%1'`）
2. `g:ai_send_target` — 通过 `:AITarget` 手动设置的 session:window.pane
3. **自动选择** — 面积最大的非当前 pane（两个 pane 时直接选另一个）
4. **交互提示** — 以上都无法确定目标时，自动弹出交互选择框

### Configuration

```vim
" Interactive mode: choose target every time you send
" 'pane'   → prompt for pane only (session+window auto)
" 'window' → prompt for window, then pane
" 0        → preset / auto-select (default)
let g:ai_tmux_interactive = 'pane'

" Force a specific pane (disables auto-select)
let g:ai_tmux_target_pane = '%1'

" Disable clipboard fallback when not in tmux
let g:ai_tmux_fallback_clipboard = 0

" Auto-select tallest pane during :AITarget (skip manual pane prompt)
let g:ai_tmux_autoset_pane = 1

" List all sessions/windows during :AITarget (default: current only)
let g:ai_tmux_always_current_session = 0
let g:ai_tmux_always_current_window = 0

" File path in output: 0 = relative (default), 1 = absolute
let g:ai_tmux_use_absolute_path = 1

" Output: 0 = full (file+lines+code block, default), 1 = raw content only
let g:ai_tmux_raw_content = 1

" Disable default mappings, use <Plug> instead
let g:ai_tmux_no_mappings = 1
nmap <leader>st <Plug>SetAITarget
vmap <leader>ss <Plug>SendSelectionToAI
```

## License

DWTFYWTPL — Do What The Fuck You Want To Public License.
