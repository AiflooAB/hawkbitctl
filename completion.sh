#!/usr/bin/env bash

_hawkbit_completion() {
    # echo "${#COMP_WORDS[@]}"
    if [[ "${COMP_WORDS[1]}" == "tags" ]] && [[ "${#COMP_WORDS[@]}" -le 3 ]]; then
        if [ "${#COMP_WORDS[@]}" -eq 3 ]; then
            COMPREPLY=($(compgen -W "-h --help list assigned create delete add unassign" -- "${COMP_WORDS[2]}"))
        else
            COMPREPLY=()
        fi
    elif [ "${COMP_WORDS[1]}" == "targets" ]; then
        if [ "${#COMP_WORDS[@]}" -eq 3 ]; then
            COMPREPLY=($(compgen -W "-h --help list show actions attributes delete" -- "${COMP_WORDS[2]}"))
        elif [ "${COMP_WORDS[2]}" == "list" ]; then
            COMPREPLY=($(compgen -W "--filter" -- "${COMP_WORDS[3]}"))
        elif [ "${COMP_WORDS[2]}" == "actions" ]; then
            COMPREPLY=($(compgen -W "--list --action" -- "${COMP_WORDS[3]}"))
        else
            COMPREPLY=()
        fi
    elif [ "${COMP_WORDS[1]}" == "rollouts" ]; then
        if [ "${#COMP_WORDS[@]}" -eq 3 ]; then
            COMPREPLY=($(compgen -W "-h --help list show delete deploygroups deploygroup-targets" -- "${COMP_WORDS[2]}"))
        else
            COMPREPLY=()
        fi
    elif [[ "${#COMP_WORDS[@]}" -le 3 ]]; then
        COMPREPLY=($(compgen -W "-h --help tags targets rollouts" -- "${COMP_WORDS[1]}"))
    fi
}

complete -F _hawkbit_completion hawkbitctl
