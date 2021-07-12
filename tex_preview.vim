let s:header = '\documentclass{article}'
let s:packages = ['\usepackage[active,tightpage]{preview}']
let s:job = 0
let s:job_mk_img = 0
let s:job_show_img = 0

function! s:show_img(job, status, event) abort
  if a:status
    return
  endif
  let job = jobstart(['./preview_image.sh', 'test0', '10', '10', '100'])
  sleep 200m 
  call s:close_job()
  let s:job = job
endfunction

function! Preview() abort
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

function! Start_preview() abort
  augroup tex_preview
    autocmd!
    autocmd TextChangedI,TextChanged <buffer> call Preview()
    autocmd BufLeave,VimLeave <buffer> call s:close_job()
  augroup END
endfunction
