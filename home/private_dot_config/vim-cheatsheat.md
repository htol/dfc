# Absolute minimum you should know about vim

## Moving around
j, k, h, l - up/down/left/right  
w, b, e - word forward/backward/to the end of word  
f, F - stops on first symbol in current line. ex. f( - going to first '(' / backward  
t, T - stops before symbol in current line / backward  
{} - goto previos/next paragraph (empty line)  
% - if cursor placed on {} or [], than moved between open/close bracers of this level  
$, _ - goto begin/end of the line  
I, A - goto first/last character of the line and enter insert mode  
0 - goto begin of the line  
gg - first line of file  
G - last line of file  
zz - move current line to center of screen  
zt - -//- to the top  
zb - -//- to the bottom  

## Copy/paste
yy - copy current line  
dd - cut current line  
p/P - put (paste) on next/current line  

## Operation with characters
x - delete one character  
s - delete one character and enter insert mode  
S - delete line and enter insert mode  
~ - capitalyse character  
r - replace current character  

## Ins ans outs
di{, ci{, yi{, vi{  
da, ca, ya, va, =a  

## g for gump
gi - jump to last insert mode  
gv - jump to last visual mode  
gq - adjust very long comment  

## Working with windows
Ctrl+w Ctrl+v - vertical split  
Ctrl+w Ctrl+ - horisontal split  
Ctrl+w h/j/k/l - move between panes  
Ctrl+w Ctrl+O - close all non active pane  
Ctrl+w Ctrl+r - Rotate windows downwards/rightwards. Swapped panes in case of 2 panes.

:Ex - file manager  

## Exit vim

:!sudo shutdown now - just kidding  
ZZ - exit vim without any changes  


## Save file without required permission

:w !sudo tee %  

## Registers
0 - always contain latest yank data  
1 - always contain last deleted data  
"" - unnamed register contain any last action with data. d/y/c/...  

% - current file. 'Ctrl+r %' to insert it in buffer or command line  
%:p - full path  
%:h - head of file name. example ":!mkdir %:h" will create a folder  
%:t - tail of file name  
%:r - root  
%:e - extention  
%:~ - relative to home direcory  

check :help filename-modifier to more  

. - last insert mode  
: - last command mode  

:call ClearRegs() - to clear registers  

## Working with macro
Enter "q" to start recording macro. Choose register to store macro, e.g. "w". Start doing required actions. Press "q" to stop recording macro.  
:%normal @w - replay macro to whole buffer. Alternative: VG:norm @w

## How to edit macro
For example write macro under "a" register. To edit enter the next command.  
:let @a='  
Press 'Ctrl+r a'. 'a' for named register where macros tored. It will populate line with register content. Don't forget closing quote.  


## Working with diff tool
:diffthis - adding current file to diff, switch to other file and enter it again  
:windo diffthis - diff all panes in window  
:diffoff - disable diff  
:windo diffoff - disable for window  
:diffupdate - update after made changes inside vim  
Ctrl+W W - switch between panes  
zr - expand all folds  
zm - colapse all folds  
zo - Open folded lines.  
zc - Close folded lines.  
do - Get changes from other window into the current window.  
dp - Put the changes from current window into the other window.  
]c - Jump to the next change.  
[c - Jump to the previous change.  
