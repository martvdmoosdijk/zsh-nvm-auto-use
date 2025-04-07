# zsh-nvm-auto-use

zsh-nvm-auto-use is a [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) plugin automatically switches node version,  `nvm use`, when a .nvmrc is detected.

## How to install

Put the script in the oh-my-zsh plugins folder

```sh
    cd ~/.oh-my-zsh/custom/plugins
    git clone git@github.com:martvdmoosdijk/zsh-nvm-auto-use.git
```

Activate the plugin in your .zshrc file

```sh
    vim ~/.zshrc
    plugins=(zsh-nvm-auto-use)
```

Restart or source your terminal

```sh
    source ~/.zshrc
```

## Note

Make sure you already have nvm loaded before this runs — usually Oh My Zsh takes care of it if you're using the nvm plugin.
