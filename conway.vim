" Adapted from Damian Conway's Vim plugins for Perl
"  https://github.com/thoughtstream/Damian-Conway-s-Vim-Setup/blob/master/plugin/trackperlvars.vim
let s:secret_codes = {}
let s:secret_codes['echo'] = 'print to screen'
let s:secret_codes['echohl'] = 'set highlight of echo statements'
let s:displaying_message = 0
highlight Secret ctermbg=blue ctermfg=yellow

function! DisplaySecret()
    let current_word = expand('<cword>')
    if has_key(s:secret_codes,current_word)
        echohl Secret
        echo   current_word.":  ".s:secret_codes[current_word]
        echohl None
        let s:displaying_message = 1
    elseif s:displaying_message==1
        echo ""
        let s:displaying_message=0
    endif

endfunction

autocmd CursorMoved  <buffer> call DisplaySecret()
autocmd CursorMovedI <buffer> call DisplaySecret()
autocmd BufLeave     <buffer> echo ""
