" Terminal Noir monochrome Vim colors.
set background=dark
highlight clear
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "terminal-noir"

highlight Normal       guifg=#e0e0e0 guibg=#0a0a0a ctermfg=252 ctermbg=0
highlight Cursor       guifg=#0a0a0a guibg=#ffffff ctermfg=0 ctermbg=15
highlight CursorLine   guibg=#111111 ctermbg=233
highlight LineNr       guifg=#555555 guibg=#0a0a0a ctermfg=240 ctermbg=0
highlight CursorLineNr guifg=#ffffff guibg=#111111 ctermfg=15 ctermbg=233
highlight Visual       guifg=#ffffff guibg=#333333 ctermfg=15 ctermbg=238
highlight Search       guifg=#000000 guibg=#e0e0e0 ctermfg=0 ctermbg=252
highlight IncSearch    guifg=#000000 guibg=#ffffff ctermfg=0 ctermbg=15
highlight StatusLine   guifg=#ffffff guibg=#1c1c1c ctermfg=15 ctermbg=234
highlight StatusLineNC guifg=#888888 guibg=#111111 ctermfg=245 ctermbg=233
highlight VertSplit    guifg=#222222 guibg=#0a0a0a ctermfg=235 ctermbg=0
highlight Pmenu        guifg=#e0e0e0 guibg=#111111 ctermfg=252 ctermbg=233
highlight PmenuSel     guifg=#000000 guibg=#e0e0e0 ctermfg=0 ctermbg=252
highlight Comment      guifg=#666666 ctermfg=242
highlight Constant     guifg=#ffffff ctermfg=15
highlight String       guifg=#c8c8c8 ctermfg=251
highlight Identifier   guifg=#e0e0e0 ctermfg=252
highlight Statement    guifg=#ffffff gui=bold ctermfg=15 cterm=bold
highlight PreProc      guifg=#c8c8c8 ctermfg=251
highlight Type         guifg=#ffffff gui=bold ctermfg=15 cterm=bold
highlight Special      guifg=#b0b0b0 ctermfg=249
highlight Error        guifg=#ffffff guibg=#2a2a2a ctermfg=15 ctermbg=235
highlight Todo         guifg=#000000 guibg=#e0e0e0 ctermfg=0 ctermbg=252
