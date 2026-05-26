" vim-tmux-aisend.vim - Send code to AI (clipboard or tmux)
" Maintainer:   linyuan
" License:      DWTFYWTPL

if exists("g:loaded_vim_tmux_aisend") && g:loaded_vim_tmux_aisend
    finish
endif
let g:loaded_vim_tmux_aisend = 1

" =========================
" Configuration
" =========================

" Target pane ID (e.g. '%1'), empty = auto-select
if !exists("g:ai_tmux_target_pane")
    let g:ai_tmux_target_pane = ''
endif

" Fallback to clipboard when no tmux target
if !exists("g:ai_tmux_fallback_clipboard")
    let g:ai_tmux_fallback_clipboard = 1
endif

" Auto-select the largest non-current pane (like tslime's autoset_pane)
if !exists("g:ai_tmux_autoset_pane")
    let g:ai_tmux_autoset_pane = 0
endif

" Lock to current session (for interactive target selection)
if !exists("g:ai_tmux_always_current_session")
    let g:ai_tmux_always_current_session = 1
endif

" Lock to current window (for interactive target selection)
if !exists("g:ai_tmux_always_current_window")
    let g:ai_tmux_always_current_window = 1
endif

" Manually specified target, set via :AITarget
" e.g. {'session': 'mysession', 'window': '1', 'pane': '2'}
if !exists("g:ai_send_target")
    let g:ai_send_target = {}
endif

" =========================
" Tmux query helpers
" =========================

function! s:IsTmux() abort
    return !empty($TMUX)
endfunction

function! s:ActiveTarget() abort
    let l:line = system('tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}"')
    let l:line = substitute(l:line, '\n', '', '')
    let [l:sess, l:rest; _] = split(l:line, ':')
    let [l:win, l:pane; _] = split(l:rest, '\.')
    return {'session': l:sess, 'window': l:win, 'pane': l:pane}
endfunction

function! s:TmuxSessions() abort
    if g:ai_tmux_always_current_session
        return [s:ActiveTarget().session]
    endif
    let l:lines = systemlist('tmux list-sessions -F "#{session_name}"')
    return map(l:lines, {_, v -> substitute(v, '\n', '', '')})
endfunction

function! s:TmuxWindows() abort
    if empty(g:ai_send_target)
        let l:session = s:ActiveTarget().session
    else
        let l:session = get(g:ai_send_target, 'session', '')
    endif

    if g:ai_tmux_always_current_window
        let l:target = s:ActiveTarget()
        return [l:target.window]
    endif

    let l:lines = systemlist('tmux list-windows -t ' . shellescape(l:session) . ' -F "#{window_index}"')
    return map(l:lines, {_, v -> substitute(v, '\n', '', '')})
endfunction

function! s:TmuxPanes() abort
    if empty(g:ai_send_target)
        let l:active = s:ActiveTarget()
        let l:session = l:active.session
        let l:window = l:active.window
    else
        let l:session = get(g:ai_send_target, 'session', '')
        let l:window = get(g:ai_send_target, 'window', '')
    endif

    let l:lines = systemlist('tmux list-panes -t ' . shellescape(l:session . ':' . l:window) . ' -F "#{pane_index}"')
    let l:panes = map(l:lines, {_, v -> substitute(v, '\n', '', '')})

    " Remove current pane only if targeting our own session:window
    if !empty(g:ai_send_target)
        let l:current = s:ActiveTarget()
        if l:current.session ==# l:session && l:current.window ==# l:window
            let l:panes = filter(l:panes, {_, v -> v !=# l:current.pane})
        endif
    endif

    return l:panes
endfunction

function! s:AutoTmuxPanes() abort
    let l:active = s:ActiveTarget()
    let l:lines = systemlist('tmux list-panes -t ' . shellescape(l:active.session . ':' . l:active.window) . ' -F "#{pane_index} #{pane_height}"')
    let l:panes = {}
    for line in l:lines
        let [idx, h; _] = split(line)
        let l:panes[idx] = str2nr(h)
    endfor

    " Remove current pane
    if has_key(l:panes, l:active.pane)
        unlet l:panes[l:active.pane]
    endif

    if empty(l:panes)
        return []
    endif

    " Return the index with greatest height
    let l:best = ''
    let l:best_h = -1
    for [idx, h] in items(l:panes)
        if h > l:best_h
            let l:best_h = h
            let l:best = idx
        endif
    endfor
    return [l:best]
endfunction

" =========================
" Interactive target selection
" =========================

function! s:TmuxVars() abort
    if !s:IsTmux()
        echo "Not in tmux"
        return
    endif

    " Session
    let l:sessions = s:TmuxSessions()
    if len(l:sessions) == 1
        let l:session = l:sessions[0]
    else
        let l:session = input('Session: ', '', 'customlist,TmuxSessionNames')
    endif
    if empty(l:session)
        return
    endif
    let g:ai_send_target['session'] = l:session

    " Window
    let l:windows = s:TmuxWindows()
    if len(l:windows) == 1
        let l:window = l:windows[0]
    else
        let l:window = input('Window: ', '', 'customlist,TmuxWindowNames')
    endif
    if empty(l:window)
        return
    endif
    let g:ai_send_target['window'] = l:window

    " Pane
    if g:ai_tmux_autoset_pane
        let l:panes = s:AutoTmuxPanes()
    else
        let l:panes = s:TmuxPanes()
    endif

    if len(l:panes) == 1
        let l:pane = l:panes[0]
    else
        let l:pane = input('Pane: ', '', 'customlist,TmuxPaneNumbers')
    endif
    if empty(l:pane)
        return
    endif
    let g:ai_send_target['pane'] = l:pane

    echo 'Target set: ' . l:session . ':' . l:window . '.' . l:pane
endfunction

" Completion (public, for customlist)
function! TmuxSessionNames(A, L, P)
    return s:TmuxSessions()
endfunction

function! TmuxWindowNames(A, L, P)
    return s:TmuxWindows()
endfunction

function! TmuxPaneNumbers(A, L, P)
    if g:ai_tmux_autoset_pane
        return s:AutoTmuxPanes()
    endif
    return s:TmuxPanes()
endfunction

" =========================
" Content building / sending
" =========================

function! s:BuildContent(start, end) abort
    let l:file = expand('%')
    let l:filetype = &filetype
    let l:lines = getline(a:start, a:end)
    let l:content = join(l:lines, "\n")
    let l:basename = fnamemodify(l:file, ':t')

    return printf(
    \ "文件：%s\n行号：%d-%d\n\n```%s\n%s\n```",
    \ l:file, a:start, a:end, l:filetype, l:content
    \)
endfunction

function! s:BuildTargetArg() abort
    if !empty(g:ai_send_target)
        let t = g:ai_send_target
        return t['session'] . ':' . t['window'] . '.' . t['pane']
    endif
    return ''
endfunction

function! s:BuildPaneId() abort
    " Priority: 1) manual pane override  2) g:ai_send_target  3) auto
    if !empty(g:ai_tmux_target_pane)
        return g:ai_tmux_target_pane
    endif

    let l:target = s:BuildTargetArg()
    if !empty(l:target)
        return l:target
    endif

    " Auto-select: largest non-current pane
    let l:panes = systemlist('tmux list-panes -F "#{pane_id} #{pane_width} #{pane_height}"')
    if len(l:panes) <= 1
        return ''
    endif

    let l:current = substitute(system('tmux display-message -p "#{pane_id}"'), '\n', '', '')

    if len(l:panes) == 2
        for line in l:panes
            let [id, w, h] = split(line)
            if id !=# l:current
                return id
            endif
        endfor
        return ''
    endif

    let l:max_area = -1
    let l:target = ''
    for line in l:panes
        let [id, w, h] = split(line)
        if id ==# l:current
            continue
        endif
        let l:area = str2nr(w) * str2nr(h)
        if l:area > l:max_area
            let l:max_area = l:area
            let l:target = id
        endif
    endfor
    return l:target
endfunction

function! s:SendToTmux(content) abort
    let l:tmp = tempname()
    call writefile(split(a:content, "\n"), l:tmp)
    let l:pane = s:BuildPaneId()

    if empty(l:pane)
        call system('tmux load-buffer ' . shellescape(l:tmp))
        call system('tmux paste-buffer -d')
    else
        call system('tmux load-buffer ' . shellescape(l:tmp))
        call system('tmux paste-buffer -t ' . l:pane . ' -d')
        call system('tmux select-pane -t ' . l:pane)
    endif

    call delete(l:tmp)
endfunction

function! s:CopyToClipboard(content) abort
    call setreg('+', a:content)
endfunction

" =========================
" Public API
" =========================

function! CopyForAI() range
    let l:content = s:BuildContent(line("'<"), line("'>"))
    call setreg('+', l:content)
    echo "Copied for AI ✅"
endfunction

function! SendForAI(start, end)
    let l:content = s:BuildContent(a:start, a:end)

    if s:IsTmux()
        call s:SendToTmux(l:content)
        echo "Sent to tmux 🚀"
        return
    endif

    if g:ai_tmux_fallback_clipboard
        call s:CopyToClipboard(l:content)
        echo "Copied to clipboard 📋"
    else
        echo "Not in tmux ❌"
    endif
endfunction

function! AISetTarget()
    call s:TmuxVars()
endfunction

function! AIClearTarget()
    let g:ai_send_target = {}
    echo "AI send target cleared, will auto-select"
endfunction

" =========================
" Commands
" =========================

command! -range CopyForAI :<line1>,<line2>call CopyForAI()
command! -range SendForAI :<line1>,<line2>call SendForAI(<line1>, <line2>)
command! AITarget call AISetTarget()
command! AIClearTarget call AIClearTarget()

" =========================
" Mappings (<Plug>)
" =========================

" Copy selection with file context to clipboard
vnoremap <silent> <Plug>CopyForAI :<C-u>call CopyForAI()<CR>

" Send selection to tmux (or fallback clipboard)
vnoremap <silent> <Plug>SendSelectionToAI :<C-u>call SendForAI(line("'<"), line("'>"))<CR>

" Send current line to tmux (or fallback clipboard)
nnoremap <silent> <Plug>SendLineToAI :call SendForAI(line("."), line("."))<CR>

" Set tmux target interactively (session:window.pane)
nnoremap <silent> <Plug>SetAITarget :call AISetTarget()<CR>

" =========================
" Default mappings (optional, opt-out with g:ai_tmux_no_mappings)
" =========================

if !exists("g:ai_tmux_no_mappings")
    vnoremap <leader>ay :<C-u>call CopyForAI()<CR>
    vnoremap <leader>at :<C-u>call SendForAI(line("'<"), line("'>"))<CR>
    nnoremap <leader>at :call SendForAI(line("."), line("."))<CR>
    nnoremap <leader>as :call AISetTarget()<CR>
endif
