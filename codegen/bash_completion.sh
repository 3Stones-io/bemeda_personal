#!/bin/bash

# Bash completion for Optimum Codegen Makefile
# Source this file or add it to your bash completion directory

_make_codegen_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Main make targets
    if [[ ${COMP_CWORD} == 1 ]]; then
        opts="new batch rm clean clean-branches resume ls help"
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
        return 0
    fi

    case "${prev}" in
    new)
        # For 'make new', complete with plan names (without .md extension)
        if [[ -d "${script_dir}/plans" ]]; then
            local plans=$(find "${script_dir}/plans" -name "*.md" -not -name "*.old" -exec basename {} .md \; 2>/dev/null)
            COMPREPLY=($(compgen -W "${plans}" -- ${cur}))
        fi
        ;;
    rm | resume)
        # For 'make rm' and 'make resume', complete with existing workspace names
        local repo_root="$(cd "${script_dir}/.." && pwd)"
        if [[ -d "${repo_root}" ]]; then
            cd "${repo_root}"
            local workspaces=$(git worktree list --porcelain 2>/dev/null | grep "^worktree" | cut -d' ' -f2 | xargs -I {} basename {} | grep -v "$(basename "${repo_root}")")
            COMPREPLY=($(compgen -W "${workspaces}" -- ${cur}))
        fi
        ;;
    esac
}

# Register the completion function
complete -F _make_codegen_completion make

# Also register for when make is called with specific targets
complete -F _make_codegen_completion -o default make
