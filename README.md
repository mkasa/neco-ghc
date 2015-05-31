# What is neco-ghc-lushtags?

neco-ghc-lushtags is a blazing fast completion plugin
for Haskell using ghc-mod, lushtags, and ghc-mod-cache.

neco-ghc-lushtags is a project forked from
[neco-ghc](https://github.com/eagletmt/neco-ghc),
so most of the functions are derived from neco-ghc.
If you have not used neco-ghc before, please see
the site first.

neco-ghc-lushtags achieves faster completion using
ghc-mod-cache, which is developed in this project.
I had been frustrated by slow ghc-mod. neco-ghc calls
ghc-mod so often, each of which calls may take a few
seconds but they often blocked vim for more than ten
seconds, which was unacceptable for me. I noticed
that results of ghc-mod could be cached in most cases,
so I developed ghc-mod-cache, which is a simple
wrapper script of ghc-mod. ghc-mod-cache caches the
result of `ghc-mod browse`. neco-ghc-lushtags can
response in less than a second after the result of
ghc-mod is cached.

Another source of frustration was that neco-ghc does
not complete functions in modules not installed.
Let me show an example. Suppose we are working on a
scaffolded Yesod site. neco-ghc does not complete
functions in non-standard modules such as Foundation,
Import, etc. neco-ghc-lushtags can completes such
functions.

## Additional features on top of neco-ghc

<<< Here comes images. (to be taken!) >>>

neco-ghc was originally implemented by @eagletmt on July 25, 2010, and then
ujihisa added some new features. neco-ghc-lushtags was forked from
neco-ghc by @mkasa on May 31, 2015.

## Install

* Install ghc-mod package by `cabal install ghc-mod`
* Install [modified version of lushtags](https://github.com/mkasa/lushtags)
* Unarchive neco-ghc-lushtags and put it into a dir of your &rtp.
* Copy ghc-mod-cache into PATH (e.g., ~/.cabal/bin)

## Usage

neco-ghc-lushtags provides `necoghc#omnifunc` for omni-completion.
I recommend adding the following in your ~/.vim/ftplugin/haskell.vim.

```vim
setlocal omnifunc=necoghc#omnifunc
```

See `:help compl-omni` for details on omni-completion.

### Completion engines
This plugin can be used as a source of
[neocomplete.vim](https://github.com/Shougo/neocomplete.vim) or
[neocomplcache.vim](https://github.com/Shougo/neocomplcache.vim).
You can enjoy auto-completions without any specific configuration.

This plugin also should work with [YouCompleteMe](https://github.com/Valloric/YouCompleteMe), but not tested.
To enable auto-completions, you have to add the following setting.

```vim
let g:ycm_semantic_triggers = {'haskell' : ['.']}
```

## Options
### `g:necoghc_enable_detailed_browse`
Default: 0

Show detailed information (type) of symbols.
You can enable it by adding `let g:necoghc_enable_detailed_browse = 1` in your vimrc.
While it is quite useful, it would take longer boot time.

This feature was introduced in ghc-mod 1.11.5.

![](http://cache.gyazo.com/f3d2c097475021615581822eee8cb6fd.png)

### `g:necoghc_debug`
Default: 0

Show error message if ghc-mod command fails.
Usually it would be noisy because `ghc-mod browse Your.Project.Module` always fails.
Use this flag only if you have some trouble.

## Troubleshoot

If for some reason the neco-ghc plugin is not being added to neocomplcache,
check that the $PATH variable in vim contains the path to your .cabal/bin
directory.

If not, add in your .vimrc:

`let $PATH = $PATH . ':' . expand("~/.cabal/bin")`

## License

[BSD3 License](http://www.opensource.org/licenses/BSD-3-Clause), the same license as ghc-mod
and neco-ghc.
