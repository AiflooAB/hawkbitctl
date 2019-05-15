#!/bin/bash

show_help() {
cat << EOF
Usage: hawkbitctl rollouts [<command>] [OPTION]...
Manage rollouts in hawkbit.

    -h, --help  display this help and exit
    -a, --all   Display all deploy groups with deploygroup-targets

Subcommands, if <command> is omitted list will be used.

    list                                            List all rollouts
    show <ROLLOUT>                                  Show details about a specific rollout
    deploygroups <ROLLOUT>                          List all deploygroups for a rollout
    deploygroup-targets <ROLLOUT> <DEPLOYGROUP>...  Show all targets for a deploygroup
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

    get_group() {
        ./get "/rollouts/$1/deploygroups/$2/targets" | \
        jq --raw-output '.content | map([ .name, .updateStatus ])[] | @tsv'
    }

    header() {
        printf "Name\\tStatus\\n---\\t---\\n"
    }

    if [[ "$3" =~ -a|--all ]]; then
        groups=$(./get "/rollouts/$2/deploygroups" | jq --raw-output .content[].id)
    else
        groups="${*:3}"
    fi

    (
        header &&
        for group in $groups; do
            echo "# group $group"
            get_group "$2" "$group"
        done
    ) | column -s '	' -t
elif [[ "$1" == "list" ]]; then
    ./get /rollouts | jq .
else
    ./get /rollouts | jq .
fi
