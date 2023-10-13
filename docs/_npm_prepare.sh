#!/bin/sh

# Installation of NPM packages
# this is made for specific user!

    mkdir "${HOME}/.npm-packages"
    echo "prefix=${HOME}/.npm-packages" >> ~/.npmrc

    cat >> ~/.bashrc <<'EOF'
    echo NPM_PACKAGES="${HOME}/.npm-packages"
    echo PATH="$NPM_PACKAGES/bin:$PATH"

    # Unset manpath so we can inherit from /etc/manpath via the `manpath` command
    unset MANPATH # delete if you already modified MANPATH elsewhere in your config
    export MANPATH="$NPM_PACKAGES/share/man:$(manpath)"
    EOF

    # wget -O- https://raw.githubusercontent.com/glenpike/npm-g_nosudo/master/npm-g-nosudo.sh | sh
    npm install -g coffee-script