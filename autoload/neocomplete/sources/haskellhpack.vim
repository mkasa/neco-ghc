
let s:source = {
    \ 'name' : 'haskellhpack',
    \ 'filetypes': { 'haskellhpack': 1 }
    \ }

function! s:push_yaml_context(context_list, item) "{{{
    let l:lst = a:context_list
    let l:indent_depth = a:item['depth']
    let l:name = a:item['name']
    while !empty(l:lst) && l:indent_depth < l:lst[-1]['depth']
        let l:lst = l:lst[:-2]
    endwhile
    if !empty(l:lst) && l:indent_depth == l:lst[-1]['depth']
        if l:lst[-1]['name'] =~# '\v^\d+$'
            let l:lst[-1]['name'] = string(l:lst[-1]['name'] + 1)
        else
            let l:lst[-1]['name'] = l:name
        endif
    else
        call add(l:lst, a:item)
    endif
    return l:lst
endfunction "}}}

function! s:get_current_context(context) "{{{
    let l:line_num = 1
    let l:current_line = line(".")
    let l:stack = []
    while l:line_num <= l:current_line
        let l:line = getline(l:line_num)
        if match(l:line, '\v^\s*#') != -1
            " Skip comments
        else
            let l:indent_depth = -1
            let l:name = ""
            let l:r = matchlist(l:line, '\v^(\s*)-')
            if !empty(l:r)
                let l:indent_depth = strlen(l:r[1])
                let l:name = "0"
                " echomsg "seq " . l:indent_depth
            else
                let l:r = matchlist(l:line, '\v^(\s*)(\S+) ?:')
                if !empty(l:r)
                    let l:indent_depth = strlen(l:r[1])
                    let l:name = l:r[2]
                    " echomsg "map " . l:indent_depth
                endif
            endif
            if 0 <= l:indent_depth
                " echomsg l:line
                let l:stack = s:push_yaml_context(l:stack, {'depth': l:indent_depth, 'name': l:name})
            endif
        endif
        let l:line_num = l:line_num + 1
    endwhile
    " let c = a:context['complete_pos'] - strlen(a:context['complete_str'])
    let c = a:context['complete_pos']
    let l:stack = s:push_yaml_context(l:stack, {'depth': c, 'name': '@'})
    let l:name_stack = []
    for i in l:stack
        call add(l:name_stack, i['name'])
    endfor
    return l:name_stack
endfunction "}}}

""" The function below was taken from neco-ghc
function! s:system(list) abort "{{{
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc && !has('nvim') ?
        \ vimproc#system(a:list) : system(join(a:list, ' '))
endfunction "}}}

function! s:source.gather_candidates(context) abort "{{{
    let l:name_stack = s:get_current_context(a:context)
    " echomsg "==="
    " echomsg a:context.complete_pos
    " echomsg "STR: " . a:context.complete_str
    " echomsg "---"
    " echomsg join(l:name_stack, "/")
    " echomsg "==="
    let l:ret_val = []
    let l:prev_name = ''
    let l:i = 0
    while l:i < len(l:name_stack)
        let l:token = l:name_stack[l:i]
        if l:token ==# 'library' || l:token ==# 'executables' || l:token ==# 'tests' || l:token ==# 'benchmarks'
            let l:prev_name = l:token
            break
        endif
        let l:i = l:i + 1
    endwhile
    let l:imm_prev_name = ''
    if 3 <= len(l:name_stack)
        let l:imm_prev_name = l:name_stack[len(l:name_stack) - 3]
    endif
    let l:cur_line = getline('.')
    if matchstr(l:cur_line, "\\v^\\s*-") !=# ''
        echom join(l:name_stack, '/')
        echom l:imm_prev_name
        if l:imm_prev_name ==# 'dependencies'
            let l:cmd = ['ghc-mod-cache', 'list_stackage', '--modules']
            let l:ret = s:system(l:cmd)
            let l:lines = split(l:ret, '\r\n\|[\r\n]')
            call extend(l:ret_val, map(l:lines, '{ "word": v:val }'))
        endif
        if l:imm_prev_name ==# 'default-extensions' || l:imm_prev_name ==# 'extensions'
            "{{{
            call extend(l:ret_val, map([
                        \ "Haskell98",
                        \ "Haskell2010",
                        \ "Unsafe",
                        \ "Trustworthy",
                        \ "Safe",
                        \ "AllowAmbiguousTypes",
                        \ "NoAllowAmbiguousTypes",
                        \ "AlternativeLayoutRule",
                        \ "NoAlternativeLayoutRule",
                        \ "AlternativeLayoutRuleTransitional",
                        \ "NoAlternativeLayoutRuleTransitional",
                        \ "Arrows",
                        \ "NoArrows",
                        \ "AutoDeriveTypeable",
                        \ "NoAutoDeriveTypeable",
                        \ "BangPatterns",
                        \ "NoBangPatterns",
                        \ "BinaryLiterals",
                        \ "NoBinaryLiterals",
                        \ "CApiFFI",
                        \ "NoCApiFFI",
                        \ "CPP",
                        \ "NoCPP",
                        \ "ConstrainedClassMethods",
                        \ "NoConstrainedClassMethods",
                        \ "ConstraintKinds",
                        \ "NoConstraintKinds",
                        \ "DataKinds",
                        \ "NoDataKinds",
                        \ "DatatypeContexts",
                        \ "NoDatatypeContexts",
                        \ "DefaultSignatures",
                        \ "NoDefaultSignatures",
                        \ "DeriveAnyClass",
                        \ "NoDeriveAnyClass",
                        \ "DeriveDataTypeable",
                        \ "NoDeriveDataTypeable",
                        \ "DeriveFoldable",
                        \ "NoDeriveFoldable",
                        \ "DeriveFunctor",
                        \ "NoDeriveFunctor",
                        \ "DeriveGeneric",
                        \ "NoDeriveGeneric",
                        \ "DeriveLift",
                        \ "NoDeriveLift",
                        \ "DeriveTraversable",
                        \ "NoDeriveTraversable",
                        \ "DisambiguateRecordFields",
                        \ "NoDisambiguateRecordFields",
                        \ "DoAndIfThenElse",
                        \ "NoDoAndIfThenElse",
                        \ "DoRec",
                        \ "NoDoRec",
                        \ "DuplicateRecordFields",
                        \ "NoDuplicateRecordFields",
                        \ "EmptyCase",
                        \ "NoEmptyCase",
                        \ "EmptyDataDecls",
                        \ "NoEmptyDataDecls",
                        \ "ExistentialQuantification",
                        \ "NoExistentialQuantification",
                        \ "ExplicitForAll",
                        \ "NoExplicitForAll",
                        \ "ExplicitNamespaces",
                        \ "NoExplicitNamespaces",
                        \ "ExtendedDefaultRules",
                        \ "NoExtendedDefaultRules",
                        \ "FlexibleContexts",
                        \ "NoFlexibleContexts",
                        \ "FlexibleInstances",
                        \ "NoFlexibleInstances",
                        \ "ForeignFunctionInterface",
                        \ "NoForeignFunctionInterface",
                        \ "FunctionalDependencies",
                        \ "NoFunctionalDependencies",
                        \ "GADTSyntax",
                        \ "NoGADTSyntax",
                        \ "GADTs",
                        \ "NoGADTs",
                        \ "GHCForeignImportPrim",
                        \ "NoGHCForeignImportPrim",
                        \ "GeneralizedNewtypeDeriving",
                        \ "NoGeneralizedNewtypeDeriving",
                        \ "ImplicitParams",
                        \ "NoImplicitParams",
                        \ "ImplicitPrelude",
                        \ "NoImplicitPrelude",
                        \ "ImpredicativeTypes",
                        \ "NoImpredicativeTypes",
                        \ "IncoherentInstances",
                        \ "NoIncoherentInstances",
                        \ "TypeFamilyDependencies",
                        \ "NoTypeFamilyDependencies",
                        \ "InstanceSigs",
                        \ "NoInstanceSigs",
                        \ "ApplicativeDo",
                        \ "NoApplicativeDo",
                        \ "InterruptibleFFI",
                        \ "NoInterruptibleFFI",
                        \ "JavaScriptFFI",
                        \ "NoJavaScriptFFI",
                        \ "KindSignatures",
                        \ "NoKindSignatures",
                        \ "LambdaCase",
                        \ "NoLambdaCase",
                        \ "LiberalTypeSynonyms",
                        \ "NoLiberalTypeSynonyms",
                        \ "MagicHash",
                        \ "NoMagicHash",
                        \ "MonadComprehensions",
                        \ "NoMonadComprehensions",
                        \ "MonadFailDesugaring",
                        \ "NoMonadFailDesugaring",
                        \ "MonoLocalBinds",
                        \ "NoMonoLocalBinds",
                        \ "MonoPatBinds",
                        \ "NoMonoPatBinds",
                        \ "MonomorphismRestriction",
                        \ "NoMonomorphismRestriction",
                        \ "MultiParamTypeClasses",
                        \ "NoMultiParamTypeClasses",
                        \ "MultiWayIf",
                        \ "NoMultiWayIf",
                        \ "NPlusKPatterns",
                        \ "NoNPlusKPatterns",
                        \ "NamedFieldPuns",
                        \ "NoNamedFieldPuns",
                        \ "NamedWildCards",
                        \ "NoNamedWildCards",
                        \ "NegativeLiterals",
                        \ "NoNegativeLiterals",
                        \ "NondecreasingIndentation",
                        \ "NoNondecreasingIndentation",
                        \ "NullaryTypeClasses",
                        \ "NoNullaryTypeClasses",
                        \ "NumDecimals",
                        \ "NoNumDecimals",
                        \ "OverlappingInstances",
                        \ "NoOverlappingInstances",
                        \ "OverloadedLabels",
                        \ "NoOverloadedLabels",
                        \ "OverloadedLists",
                        \ "NoOverloadedLists",
                        \ "OverloadedStrings",
                        \ "NoOverloadedStrings",
                        \ "PackageImports",
                        \ "NoPackageImports",
                        \ "ParallelArrays",
                        \ "NoParallelArrays",
                        \ "ParallelListComp",
                        \ "NoParallelListComp",
                        \ "PartialTypeSignatures",
                        \ "NoPartialTypeSignatures",
                        \ "PatternGuards",
                        \ "NoPatternGuards",
                        \ "PatternSignatures",
                        \ "NoPatternSignatures",
                        \ "PatternSynonyms",
                        \ "NoPatternSynonyms",
                        \ "PolyKinds",
                        \ "NoPolyKinds",
                        \ "PolymorphicComponents",
                        \ "NoPolymorphicComponents",
                        \ "PostfixOperators",
                        \ "NoPostfixOperators",
                        \ "QuasiQuotes",
                        \ "NoQuasiQuotes",
                        \ "Rank2Types",
                        \ "NoRank2Types",
                        \ "RankNTypes",
                        \ "NoRankNTypes",
                        \ "RebindableSyntax",
                        \ "NoRebindableSyntax",
                        \ "RecordPuns",
                        \ "NoRecordPuns",
                        \ "RecordWildCards",
                        \ "NoRecordWildCards",
                        \ "RecursiveDo",
                        \ "NoRecursiveDo",
                        \ "RelaxedLayout",
                        \ "NoRelaxedLayout",
                        \ "RelaxedPolyRec",
                        \ "NoRelaxedPolyRec",
                        \ "RoleAnnotations",
                        \ "NoRoleAnnotations",
                        \ "ScopedTypeVariables",
                        \ "NoScopedTypeVariables",
                        \ "StandaloneDeriving",
                        \ "NoStandaloneDeriving",
                        \ "StaticPointers",
                        \ "NoStaticPointers",
                        \ "Strict",
                        \ "NoStrict",
                        \ "StrictData",
                        \ "NoStrictData",
                        \ "TemplateHaskell",
                        \ "NoTemplateHaskell",
                        \ "TemplateHaskellQuotes",
                        \ "NoTemplateHaskellQuotes",
                        \ "TraditionalRecordSyntax",
                        \ "NoTraditionalRecordSyntax",
                        \ "TransformListComp",
                        \ "NoTransformListComp",
                        \ "TupleSections",
                        \ "NoTupleSections",
                        \ "TypeApplications",
                        \ "NoTypeApplications",
                        \ "TypeInType",
                        \ "NoTypeInType",
                        \ "TypeFamilies",
                        \ "NoTypeFamilies",
                        \ "TypeOperators",
                        \ "NoTypeOperators",
                        \ "TypeSynonymInstances",
                        \ "NoTypeSynonymInstances",
                        \ "UnboxedTuples",
                        \ "NoUnboxedTuples",
                        \ "UndecidableInstances",
                        \ "NoUndecidableInstances",
                        \ "UndecidableSuperClasses",
                        \ "NoUndecidableSuperClasses",
                        \ "UnicodeSyntax",
                        \ "NoUnicodeSyntax",
                        \ "UnliftedFFITypes",
                        \ "NoUnliftedFFITypes",
                        \ "ViewPatterns",
                        \ "NoViewPatterns",
                        \ ], '{ "word": v:val }'))
            "}}}
        endif
        return l:ret_val
    endif
    if a:context.complete_pos == 0
        call extend(l:ret_val, map([
                  \ 'name',
                  \ 'version',
                  \ 'synopsis',
                  \ 'description',
                  \ 'category',
                  \ 'stability',
                  \ 'homepage',
                  \ 'bug-reports',
                  \ 'author',
                  \ 'maintainer',
                  \ 'copyright',
                  \ 'license',
                  \ 'license-file',
                  \ 'tested-with',
                  \ 'build-type',
                  \ 'extra-source-files',
                  \ 'data-files',
                  \ 'github',
                  \ 'git',
                  \ 'flags',
                  \ 'library',
                  \ 'executables',
                  \ 'tests',
                  \ 'benchmarks',
                  \ 'source-dirs',
                  \ 'default-extensions',
                  \ 'other-extention',
                  \ 'ghc-options',
                  \ 'ghc-prof-options',
                  \ 'cpp-options',
                  \ 'cc-options',
                  \ 'c-sources',
                  \ 'extra-lib-dirs',
                  \ 'extra-libraries',
                  \ 'include-dirs',
                  \ 'install-includes',
                  \ 'ld-options',
                  \ 'buildable',
                  \ 'dependencies',
                  \ 'build-tools',
                  \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'library' || l:prev_name ==# 'executables' || l:prev_name ==# 'tests' || l:prev_name ==# 'benchmarks'
        call extend(l:ret_val, map([
                      \ 'source-dirs',
                      \ 'default-extensions',
                      \ 'other-extension',
                      \ 'ghc-options',
                      \ 'ghc-prof-options',
                      \ 'cpp-options',
                      \ 'cc-options',
                      \ 'c-sources',
                      \ 'extra-lib-dirs',
                      \ 'extra-libraries',
                      \ 'include-dirs',
                      \ 'install-includes',
                      \ 'ld-options',
                      \ 'buildable',
                      \ 'dependencies',
                      \ 'build-tools',
                      \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'library'
        call extend(l:ret_val, map([
                      \ 'exposed',
                      \ 'exposed-modules',
                      \ 'other-modules',
                      \ 'reexported-modules',
                      \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'executables' || l:prev_name ==# 'tests' || l:prev_name ==# 'benchmarks'
        call extend(l:ret_val, map([
                      \ 'main',
                      \ 'other-modules',
                      \ ], '{ "word": v:val }'))
    endif
    if l:prev_name ==# 'flags'
        call extend(l:ret_val, map([
                      \ 'description',
                      \ 'manual',
                      \ 'default',
                      \ ], '{ "word": v:val }'))
    endif
    call extend(l:ret_val, map([
                  \ 'when',
                  \ 'condition',
                  \ ], '{ "word": v:val }'))
    return l:ret_val
endfunction "}}}
  
function! neocomplete#sources#haskellhpack#define() abort "{{{
    return s:source
endfunction "}}}
