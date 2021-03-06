let s:save_cpo = &cpo
set cpo&vim

" ns-list {{{
function! iced#nrepl#op#cider#sync#ns_list() abort
  if !iced#nrepl#is_connected()
    call iced#message#error('not_connected')
    return ''
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-list',
      \ 'session': iced#nrepl#current_session(),
      \ })
endfunction " }}}

" ns-vars-with-meta {{{
function! iced#nrepl#op#cider#sync#ns_vars(ns) abort
  if !iced#nrepl#is_connected()
    call iced#message#error('not_connected')
    return ''
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-vars-with-meta',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ 'verbose': v:false,
      \ })
endfunction " }}}

" ns-path {{{
function! iced#nrepl#op#cider#sync#ns_path(ns) abort
  if !iced#nrepl#is_connected()
    call iced#message#error('not_connected')
    return ''
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-path',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ })
endfunction " }}}

" ns-aliases {{{
function! iced#nrepl#op#cider#sync#ns_aliases(ns) abort
  if !iced#nrepl#is_connected()
    call iced#message#error('not_connected')
    return ''
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-aliases',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ })
endfunction " }}}

" classpath {{{
function! iced#nrepl#op#cider#sync#classpath() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  return iced#nrepl#sync#send({
      \ 'op': 'classpath',
      \ 'session': iced#nrepl#current_session(),
      \ })
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
