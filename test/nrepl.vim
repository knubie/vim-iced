let s:suite  = themis#suite('iced.nrepl')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl.vim')
let s:ch = themis#helper('iced_channel')

function! s:fixture() abort
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs', 'cljs-session')
  call iced#nrepl#set_session('repl', 'repl-session')
endfunction

function! s:suite.set_clj_session_test() abort
  call s:fixture()
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#current_session(), 'clj-session')
endfunction

function! s:suite.set_cljs_session_test() abort
  call s:fixture()
  call iced#nrepl#change_current_session('cljs')
  call s:assert.equals(iced#nrepl#current_session(), 'cljs-session')
endfunction

function! s:suite.set_repl_session_test() abort
  call s:fixture()
  call s:assert.equals(iced#nrepl#repl_session(), 'repl-session')
endfunction

function! s:suite.set_invalid_session_test() abort
  try
    call iced#nrepl#set_session('invalid',  'session')
  catch
    call assert_exception('Invalid session-key to set:')
  endtry
endfunction

function! s:suite.change_to_invalid_session_test() abort
  try
    call s:fixture()
    call iced#nrepl#change_current_session('invalid')
  catch
    call assert_exception('Invalid session-key to change:')
  endtry
endfunction

function! s:suite.is_connected_test() abort
  call s:ch.define_test_state({'status_value': 'open'})
  call iced#state#start_by_name('nrepl', {'port': 1234})
  call s:assert.true(iced#nrepl#is_connected())

  call iced#state#stop()
  call s:ch.define_test_state({'status_value': 'fail'})
  call iced#state#start_by_name('nrepl', {'port': 1234})
  call s:assert.false(iced#nrepl#is_connected())
endfunction

function! s:suite.connect_test() abort
  let test = {'session_patterns': ['foo-session', 'bar-session']}
  function! test.relay(msg) abort
    if a:msg['op'] ==# 'clone'
      return {'status': ['done'], 'new-session': remove(self.session_patterns, 0)}
    endif
    return {'status': ['done']}
  endfunction

  " # status_value
  "   1.fail means not connected yet
  "   2.fail means not connected by auto connection
  "   3.open means connection established
  call s:ch.define_test_state({
   \ 'status_value': 'open',
   \ 'relay': {msg -> test.relay(msg)},
   \ })

  set nohidden
  call s:assert.equals(iced#nrepl#connect(1234), v:false)

  " "call iced#state#stop()
  set hidden
  call s:assert.equals(iced#nrepl#connect(1234), v:true)
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call s:assert.equals(iced#nrepl#repl_session(), 'foo-session')
  call s:assert.equals(iced#nrepl#current_session(), 'bar-session')
endfunction

function! s:suite.connect_failure_test() abort
  call s:ch.define_test_state({'status_value': 'fail'})
  set hidden
  call s:assert.equals(iced#nrepl#connect(1234), v:false)
endfunction

function! s:suite.disconnect_test() abort
  let test = {'closed_sessions': []}
  function! test.relay(msg) abort
    let op = a:msg['op']
    if op ==# 'ls-sessions'
      return {'status': ['done'], 'sessions': ['foo-session', 'bar-session']}
    elseif op ==# 'close'
      call add(self.closed_sessions, a:msg['session'])
      return {'status': ['done']}
    endif
    return {'status': ['done']}
  endfunction

  call s:ch.start_test_state({
   \ 'status_value': 'open',
   \ 'relay': {msg -> test.relay(msg)},
   \ })

  call iced#nrepl#disconnect()
  call s:assert.equals(test.closed_sessions, ['foo-session', 'bar-session'])
endfunction

function! s:split_half(s) abort
  let l = len(a:s)
  let i = l / 2
  return [a:s[0:i], strpart(a:s, i+1)]
endfunction

function! s:suite.eval_test() abort
  let test = {}
  function! test.relay_raw(msg) abort
    if a:msg['op'] !=# 'eval' | return '' | endif

    let resp1 = iced#state#get('bencode').encode({'id': 123, 'ns': 'foo.core', 'value': 6})
    let resp2 = iced#state#get('bencode').encode({'id': 123, 'status': ['done']})
    return (s:split_half(resp1) + s:split_half(resp2))
  endfunction

  function! test.result_callback(result) abort
    let self['result'] = a:result
  endfunction

  call s:ch.start_test_state({
    \ 'status_value': 'open',
    \ 'is_raw': v:true,
    \ 'relay': {msg -> test.relay_raw(msg)},
    \ })

  call iced#nrepl#eval(
    \ '(+ 1 2 3)',
    \ {result -> test.result_callback(result)},
    \ {'id': 123},
    \ )
  call s:assert.equals(test.result, {'status': ['done'], 'id': 123, 'ns': 'foo.core', 'value': 6})
endfunction

function! s:suite.get_message_ids_test() abort
  call s:assert.equals([123], s:funcs.get_message_ids([{'id': 123}]))
  call s:assert.equals([123, 234], s:funcs.get_message_ids([{'id': 123}, {'id': 234}]))
  call s:assert.equals([123, 234], s:funcs.get_message_ids([{'id': 123}, {'id': 234}, {'id': 123}]))
  call s:assert.equals([-1], s:funcs.get_message_ids([{'foo': 'bar'}]))
  call s:assert.equals([-1, 123], s:funcs.get_message_ids([{'foo': 'bar'}, {'id': 123}]))
endfunction

function! s:suite.multiple_different_ids_response_test() abort
  let test = {}
  function! test.relay_raw(msg) abort
    if a:msg['op'] !=# 'eval' | return '' | endif
    let resp1 = iced#state#get('bencode').encode({'id': 123, 'ns': 'foo.core', 'value': 6, 'status': ['done']})
    let resp2 = iced#state#get('bencode').encode({'id': 234, 'ns': 'bar.core', 'value': 'baaaarrrr', 'status': ['done']})
    return printf('%s%s', resp1, resp2)
  endfunction

  function! test.callback_for_123(result) abort
    let self['result123'] = a:result
  endfunction

  function! test.callback_for_234(result) abort
    let self['result234'] = a:result
  endfunction

  call s:ch.start_test_state({
        \ 'status_value': 'open',
        \ 'is_raw': v:true,
        \ 'relay': {msg -> test.relay_raw(msg)}})
  call s:funcs.set_message(234, {'op': 'eval', 'callback': test.callback_for_234})

  call iced#nrepl#eval('(+ 1 2 3)', {result -> test.callback_for_123(result)}, {'id': 123})
  call s:assert.equals(test.result123, {'status': ['done'], 'id': 123, 'ns': 'foo.core', 'value': 6})
  call s:assert.equals(test.result234, {'status': ['done'], 'id': 234, 'ns': 'bar.core', 'value': 'baaaarrrr'})

  call s:funcs.clear_messages()
endfunction
