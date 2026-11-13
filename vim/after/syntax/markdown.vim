" " Add support for TOML and JSON front matter
" unlet b:current_syntax

" " syntax include @Yaml syntax/yaml.vim
" " syntax region yamlFrontMatter start=/\%^---$/ end=/^---$/ keepend contains=@Yaml

" syntax include @Toml syntax/Toml.vim
" syntax region tomlFrontMatter start=/\%^+++$/ end=/^+++$/ keepend contains=@Toml

" syntax include @Json syntax/Json.vim
" syntax region jsonFrontMatter start=/\%^{$/ end=/^}$/ keepend contains=@Json

" " syn include @yamlTop syntax/yaml.vim
" " syn region Comment matchgroup=mkdDelimiter start="\%^---$" end="^\(---\|\.\.\.\)$" contains=@yamlTop keepend
" " unlet! b:current_syntax

" try
"   syn include @tomlTop syntax/toml.vim
"   syn region Comment matchgroup=mkdDelimiter start="\%^+++$" end="^+++$" transparent contains=@tomlTop keepend
"   unlet! b:current_syntax
" catch /E484/
"   syn region Comment matchgroup=mkdDelimiter start="\%^+++$" end="^+++$"
" endtry

" try
"   syn include @jsonTop syntax/json.vim
"   syn region Comment matchgroup=mkdDelimiter start="\%^{$" end="^}$" contains=@jsonTop keepend
"   unlet! b:current_syntax
" catch /E484/
"   syn region Comment matchgroup=mkdDelimiter start="\%^{$" end="^}$"
" endtry

" " setlocal textwidth=80

" " The syntax include calls above unset b:current_syntax and never put
" " it back, leaving the buffer looking like no syntax is loaded.
" let b:current_syntax = "markdown"
