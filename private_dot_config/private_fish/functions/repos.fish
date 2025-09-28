function repos --description 'List of local repos'
    cd (ls -d ~/repos/* | fzf)
end
