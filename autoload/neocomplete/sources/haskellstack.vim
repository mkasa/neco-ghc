
let s:source = {
    \ 'name' : 'haskellstack',
    \ 'filetypes': { 'haskellstack': 1 }
    \ }

""" NOTE: I don't fully understand the line below...
let g:neocomplete#keyword_patterns.haskellstack = '\v:\s*\zs\S{-}\ze|^\s*-\s*\zs\S{-}\ze|^\s*\zs\S{-}\ze'

function! s:push_yaml_context(context_list, item) "{{{
    let l:lst = a:context_list
    let l:indent_depth = a:item['depth']
    let l:name = a:item['name']
    while !empty(l:lst) && l:indent_depth < l:lst[-1]['depth']
        let l:lst = l:lst[:-2]
    endwhile
    if !empty(l:lst) && l:indent_depth == l:lst[-1]['depth']
        if l:lst[-1]['name'] =~# '\v^\d+$'
            let l:lst[-1]['name'] = string(l:lst[-1]['name'] + 1)
        else
            let l:lst[-1]['name'] = l:name
        endif
    else
        call add(l:lst, a:item)
    endif
    return l:lst
endfunction "}}}

function! s:get_current_context(context) "{{{
    let l:line_num = 1
    let l:current_line = line(".")
    let l:stack = []
    while l:line_num <= l:current_line
        let l:line = getline(l:line_num)
        if match(l:line, '\v^\s*#') != -1
            " Skip comments
        else
            let l:indent_depth = -1
            let l:name = ""
            let l:r = matchlist(l:line, '\v^(\s*)-')
            if !empty(l:r)
                let l:indent_depth = strlen(l:r[1])
                let l:name = "0"
                " echomsg "seq " . l:indent_depth
            else
                let l:r = matchlist(l:line, '\v^(\s*)(\S+) ?:')
                if !empty(l:r)
                    let l:indent_depth = strlen(l:r[1])
                    let l:name = l:r[2]
                    " echomsg "map " . l:indent_depth
                endif
            endif
            if 0 <= l:indent_depth
                " echomsg l:line
                let l:stack = s:push_yaml_context(l:stack, {'depth': l:indent_depth, 'name': l:name})
            endif
        endif
        let l:line_num = l:line_num + 1
    endwhile
    " let c = a:context['complete_pos'] - strlen(a:context['complete_str'])
    let c = a:context['complete_pos']
    let l:stack = s:push_yaml_context(l:stack, {'depth': c, 'name': '@'})
    let l:name_stack = []
    for i in l:stack
        call add(l:name_stack, i['name'])
    endfor
    return l:name_stack
endfunction "}}}

""" The function below was taken from neco-ghc
function! s:system(list) abort "{{{
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc && !has('nvim') ?
        \ vimproc#system(a:list) : system(join(a:list, ' '))
endfunction "}}}

function! s:source.gather_candidates(context) abort "{{{
    let l:name_stack = s:get_current_context(a:context)
    echomsg "==="
    echomsg a:context.complete_pos
    echomsg "STR: " . a:context.complete_str
    echomsg "---"
    echomsg join(l:name_stack, "/")
    echomsg "==="
    let l:ret_val = []
    let l:prev_name = ''
    let l:i = 0
    while l:i < len(l:name_stack)
        let l:token = l:name_stack[l:i]
        if l:token ==# 'packages' || l:token ==# 'resolver' || l:token ==# 'image'
                    \ || l:token ==# 'flags'
            let l:prev_name = l:token
            break
        endif
        let l:i = l:i + 1
    endwhile
    let l:imm_prev_name = ''
    if 3 <= len(l:name_stack)
        let l:imm_prev_name = l:name_stack[len(l:name_stack) - 3]
    endif
    let l:ex_prev_name = ''
    if 2 <= len(l:name_stack)
        let l:ex_prev_name = l:name_stack[len(l:name_stack) - 2]
    endif
    let l:cur_line = getline('.')
    if l:ex_prev_name ==# 'resolver'
        let l:lts_paths = glob("~/.stack/build-plan/lts-*.yaml", 0, 1)
        for l:i in sort(l:lts_paths)
            echom l:i
            call add(l:ret_val, {'word': fnamemodify(l:i, ':t:r')})
        endfor
        return l:ret_val
    endif
    if matchstr(l:cur_line, "\\v^\\s*-") !=# ''
        echom join(l:name_stack, '/')
        echom l:imm_prev_name
        if l:imm_prev_name ==# 'resolver'
            let l:cmd = ['ghc-mod-cache', 'list_stackage', '--modules']
            let l:ret = s:system(l:cmd)
            let l:lines = split(l:ret, '\r\n\|[\r\n]')
            call extend(l:ret_val, map(l:lines, '{ "word": v:val }'))
        endif
        return l:ret_val
    endif
    if a:context.complete_pos == 0
        call extend(l:ret_val, map([
                  \ 'packages',
                  \ 'resolver',
                  \ 'extra-deps',
                  \ 'flags',
                  \ 'image',
                  \ 'user-message',
                  \ 'extra-package-dbs',
                  \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'packages'
        call extend(l:ret_val, map([
                      \ 'location',
                      \ 'subdirs',
                      \ 'extra-dep',
                      \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'location'
        call extend(l:ret_val, map([
                      \ 'git',
                      \ 'hg',
                      \ 'commit',
                      \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'image'
        call extend(l:ret_val, map([
                      \ 'containers',
                      \ 'base',
                      \ 'add',
                      \ 'static',
                      \ 'entry-points',
                      \ ], '{ "word": v:val }'))
    endif
    call extend(l:ret_val, map([
                  \ 'when',
                  \ 'condition',
                  \ ], '{ "word": v:val }'))
    return l:ret_val
endfunction "}}}

function! neocomplete#sources#haskellstack#define() abort "{{{
    return s:source
endfunction "}}}
