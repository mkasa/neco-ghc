
autocmd BufWritePost package.yaml execute '!ghc-mod-cache modules > /dev/null'
