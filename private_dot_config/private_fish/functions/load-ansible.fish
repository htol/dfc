function load-ansible
    set A ~/.local/ansible
    set AVENV {$A}/venv
    if test -d {$AVENV}
        echo "Loading venv"
        . {$AVENV}/bin/activate.fish
    else
        echo "Creating venv"
        cd {$A}
        python3 -m venv venv
        . {$AVENV}/bin/activate.fish
        echo "Installing requirements"
        python3 -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install ansible-lint yamllint
    end

    if test -f ~/.local/ansible/hacking/env-setup.fish
        source ~/.local/ansible/hacking/env-setup.fish
        echo "Ansible environment loaded"
    end
end
  
