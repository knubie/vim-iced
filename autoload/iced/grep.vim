let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_target = '{{user.dir}}{{separator}}**{{separator}}*.{clj,cljs,cljc}'
let g:iced#grep#target = get(g:, 'iced#grep#target', s:default_target)

function! iced#grep#exe(kw) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let user_dir = iced#nrepl#system#user_dir()
  let separator = iced#nrepl#system#separator()
  if empty(user_dir) || empty(separator) | return | endif

  let kw = empty(a:kw) ? expand('<cword>') : a:kw
  let target = g:iced#grep#target
  let target = substitute(target, '{{user\.dir}}', user_dir, 'g')
  let target = substitute(target, '{{separator}}', separator, 'g')

  silent exe printf(':grep %s %s', kw, target)
  redraw!
endfunction

function! s:fixme(_, out) abort
  let ef = &errorformat
  let &errorformat = &grepformat
  "echom printf('FIMXE err: %s', &errorformat)
  try
    "echom printf('FIXME %s', a:out)
    silent exe printf(':cexpr "%s"', a:out)
  finally
    let &errorformat = ef
  endtry
endfunction

function! iced#grep#job(kw) abort
  " &errorformat
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let user_dir = iced#nrepl#system#user_dir()
  let separator = iced#nrepl#system#separator()
  if empty(user_dir) || empty(separator) | return | endif

  let kw = empty(a:kw) ? expand('<cword>') : a:kw
  let target = g:iced#grep#target
  let target = substitute(target, '{{user\.dir}}', user_dir, 'g')
  let target = substitute(target, '{{separator}}', separator, 'g')
  "let arg = printf('%s %s', kw, target)
  let arg = kw

  if &grepprg ==# 'internal'
    silent exe printf(':grep %s', arg)
  else
    let command = &grepprg
    if stridx(command, '$*') != -1
      let command = substitute(command, '$\*', arg, 'g')
    else
      let command = printf('%s %s', command, arg)
    endif
    echom printf('FIXME command: %s', ['sh', '-c', command])
    call iced#compat#job_start(['sh', '-c', command], {
          \ 'out_cb': funcref('s:fixme'),
          \ })
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
