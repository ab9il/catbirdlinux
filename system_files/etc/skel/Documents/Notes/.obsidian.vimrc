" -----------------------------------------------------------------------------
" This config is targeted for Obsidian
" -----------------------------------------------------------------------------

set clipboard=unnamedplus
set tabstop=4

" -----------------------------------------------------------------------------
" Basic mappings
" -----------------------------------------------------------------------------

" Seamlessly treat visual lines as actual lines when moving around.
noremap j gj
noremap k gk
noremap <Down> gj
noremap <Up> gk
inoremap <Down> <C-o>gj
inoremap <Up> <C-o>gk

" Clear search highlights.
map <Leader><Space> :let @/=''<CR>
nnoremap <silent> // :noh<CR>

" Keep cursor at the bottom of the visual selection after you yank it.
vmap y ygv<Esc>

" Save with Ctrl-s
nnoremap <C-s> :w<CR>
inoremap <C-s> <ESC>:w<CR>

