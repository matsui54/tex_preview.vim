let s:header = '\documentclass{article}'
let s:packages = ['\usepackage[active,tightpage]{preview}']
let s:job = 0
let s:job_mk_img = 0
let s:job_show_img = 0
let s:edit_bufnr = -1
let s:edit_winid = -1

function! s:show_img(job, status, event) abort
  if a:status
    return
  endif
  let job = jobstart(['./preview_image.sh', 'test0', '10', '10', '100'])
  sleep 200m 
  call s:close_job()
  let s:job = job
endfunction

function! s:preview() abort
  let bufline = getbufline('%', 1, '$')
  let bufline[0] = '$' . bufline[0]
  let bufline[-1] = bufline[-1] . '$'
  let lines = [s:header]
  let lines += s:packages
  call add(lines, '\begin{document}')
  call add(lines, '\begin{preview}')
  let lines += bufline
  call add(lines, '\end{preview}')
  call add(lines, '\end{document}')

  " let tmpfile = tempname()
  call writefile(lines, "test0.tex")
  call s:close_platex_job()
  let s:job_mk_img = jobstart(['./mk_img.sh', 'test0'], {'on_exit': function('s:show_img')})
  " let s:job = jobstart(['./preview_image.sh', 'test0', '10', '10', '100'])
endfunction

function! Start_preview(mode) abort
  call s:init_edit_buffer()
  augroup tex_preview
    autocmd!
    autocmd TextChangedI,TextChanged <buffer> call s:preview()
    autocmd BufLeave,VimLeave <buffer> call s:close_job()
  augroup END
endfunction

function! s:close_platex_job() abort
  if s:job_mk_img <= 0
    return
  endif

  if has('nvim')
    call jobstop(s:job_mk_img)
  elseif type(s:job_mk_img) == v:t_job
    call job_stop(s:job_mk_img)
  endif

  let s:job_mk_img = 0
endfunction

function! s:init_edit_buffer() abort
  if win_findbuf(s:edit_bufnr) == [s:edit_winid]
    call win_gotoid(s:edit_winid)
    return
  endif

  let edit_bufname = 'tex_preview://'
  " call nvim_open_win(bufnr('%'), v:true, {
  "      \ 'relative': 'win',
  "      \ 'win': win_getid(),
  "      \ 'anchor': "SW",
  "      \ 'row': str2nr(winheight(0)),
  "      \ 'col': str2nr(0),
  "      \ 'width': winwidth(0),
  "      \ 'height': 5,
  "      \ })
  let bufnr = bufadd(edit_bufname)
  topleft split
  execute bufnr 'buffer'
  resize 7

  let s:edit_bufnr = bufnr('%')
  let s:edit_winid = win_getid()

  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nolist
  setlocal nobuflisted
  setlocal nofoldenable
  setlocal foldcolumn=0
  setlocal colorcolumn=
  setlocal nonumber
  setlocal norelativenumber
  setlocal noswapfile

  nnoremap <buffer><silent> <Plug>(command_insert_line)
        \ :<C-u>call <SID>insert_line()<CR>
  inoremap <buffer><silent> <Plug>(command_insert_line)
        \ <ESC>:call <SID>insert_line()<CR>

  nnoremap <buffer><silent> <Plug>(command_quit)
        \ :<C-u>close<CR>

  nmap <buffer><CR> <Plug>(command_insert_line)
  nmap <buffer> q   <Plug>(command_quit)

  call deletebufline('%', 1, '$')
  setlocal filetype=tex
endfunction

function! s:insert_line() abort
  stopinsert
  let lines = getbufline('%', 1, '$')
  call substitute(lines[-1], '\n$', '', '')
  close
  call s:paste(lines)
endfunction

function! s:paste(value) abort
  let save_regcont = @"
  let save_regtype = getregtype('"')
  call setreg('"', a:value, 'v')
  normal! ""p
  call setreg('"', save_regcont, save_regtype)
endfunction

function! s:close_job() abort
  if s:job <= 0
    return
  endif

  if has('nvim')
    call jobstop(s:job)
  elseif type(s:job) == v:t_job
    call job_stop(s:job)
  endif

  let s:job = 0
endfunction

inoremap <buffer><silent> <Plug>(tex_preview_start)
      \ <ESC>:call Start_preview('i')<CR>

imap <c-y> <Plug>(tex_preview_start)
