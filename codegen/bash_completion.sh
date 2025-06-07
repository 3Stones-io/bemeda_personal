#!/bin/bash

# Bash completion for Optimum Codegen (make and ocg commands)
# Source this file or add it to your bash completion directory

_codegen_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prev="${COMP_WORDS[COMP_CWORD - 1]}" cmd="${COMP_WORDS[0]}"
    COMPREPLY=()

    # Find codegen directory
    local script_dir
    if [[ "$cmd" == "make" ]]; then
        script_dir="$(pwd)"
        [[ ! -f "$script_dir/Makefile" ]] || ! grep -q "Optimum Codegen" "$script_dir/Makefile" 2>/dev/null && return 0
    else
        local cmd_path=$(command -v "$cmd" 2>/dev/null)
        script_dir=$(cd "$(dirname "${cmd_path:-${BASH_SOURCE[0]}}")" && pwd)
        [[ -n "$cmd_path" ]] && script_dir=$(cd "$(dirname "$(readlink -f "$cmd_path" 2>/dev/null || echo "$cmd_path")")" && pwd)
    fi

    # Complete main commands
    if [[ ${COMP_CWORD} == 1 ]]; then
        local opts="new batch rm clean clean-branches resume ls help"
        [[ "$cmd" == "make" ]] && opts="$opts install uninstall"
        [[ "$cmd" =~ ^(ocg|optimum_codegen)$ ]] && opts="$opts uninstall"
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
        return 0
    fi

    # Complete arguments
    case "$prev" in
        new)
            [[ -d "$script_dir/plans" ]] && COMPREPLY=($(compgen -W "$(find "$script_dir/plans" -name "*.md" -not -name "*.old" -exec basename {} .md \; 2>/dev/null)" -- "$cur"))
            ;;
        rm|resume)
            local repo_root="$(cd "$script_dir/.." && pwd)"
            [[ -d "$repo_root" ]] && cd "$repo_root" && COMPREPLY=($(compgen -W "$(git worktree list --porcelain 2>/dev/null | grep "^worktree" | cut -d' ' -f2 | xargs -I {} basename {} | grep -v "$(basename "$repo_root")")" -- "$cur"))
            ;;
    esac
}

complete -F _codegen_completion make ocg optimum_codegen
