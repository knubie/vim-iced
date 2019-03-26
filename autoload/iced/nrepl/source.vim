let s:save_cpo = &cpo
set cpo&vim

function! s:show_source(resp) abort
  if !has_key(a:resp, 'out') || trim(a:resp['out']) ==# 'Source not found'
    call iced#message#error('not_found')
    return
  endif

  call iced#state#get('document_buffer').open(a:resp['out'], 'clojure')
endfunction

function! iced#nrepl#source#show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  let source_ns = (iced#nrepl#current_session_key() ==# 'clj')
      \ ? 'clojure.repl'
      \ : 'cljs.repl'

  let code = printf('(%s/source %s)', source_ns, symbol)
  call iced#nrepl#send({
      \ 'id': iced#nrepl#id(),
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#repl_session(),
      \ 'verbose': v:false,
      \ 'callback': funcref('s:show_source'),
      \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
