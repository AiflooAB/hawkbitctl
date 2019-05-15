#!/bin/bash

show_help() {
cat << EOF
Usage: hawkbitctl rollouts [<command>]
Manage rollouts in hawkbit.

    -h, --help  display this help and exit

Subcommands, if <command> is omitted list will be used.

    list                                            List all rollouts
    show <ROLLOUT>                                  Show details about a specific rollout
    deploygroups <ROLLOUT>                          List all deploygroups for a rollout
    deploygroup-targets <ROLLOUT> <DEPLOYGROUP>     Show all targets for a deploygroup
EOF
}

if [[ "$1" =~ -h|--help ]]; then
    show_help
    exit 0
elif [[ "$1" == "show" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for rollouts show"
        exit 1
    fi

    ./get "/rollouts/$2" | jq .
elif [[ "$1" == "deploygroups" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for rollouts deploygroups"
        exit 1
    fi

    (
        printf "Name\\tID\\tStatus\\tTargets\\n---\\t---\\t---\\t---\\n" && 
        ./get "/rollouts/$2/deploygroups" | \
        jq --raw-output '.content | map([ .name, .id, .status, .totalTargets ])[] | @tsv'
    )| column -s '	' -t
elif [[ "$1" == "deploygroup-targets" ]]; then
    if [[ -z $2 ]] || [[ -z $3 ]]; then
        echo >&2 "Rollout ID or deploygroup ID missing"
        exit 1
    fi
    (
        printf "Name\\tStatus\\n---\\t---\\n" && 
        ./get "/rollouts/$2/deploygroups/$3/targets" | \
        jq --raw-output '.content | map([ .name, .updateStatus ])[] | @tsv'
    )| column -s '	' -t
elif [[ "$1" == "list" ]]; then
    ./get /rollouts | jq .
else
    ./get /rollouts | jq .
fi
