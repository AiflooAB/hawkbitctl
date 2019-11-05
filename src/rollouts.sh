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
    delete <ROLLOUT>                                Delete a rollout
    deploygroups <ROLLOUT>                          List all deploygroups for a rollout
    deploygroup-targets <ROLLOUT> <DEPLOYGROUP>...  Show all targets for a deploygroup
EOF
}

list_rollouts() {
    (
    printf "ID\\tName\\tCreated at\\tLast modified\\tStatus\\t# Targets\\tDescription\\n---\\t---\\t---\\t---\\t---\\t---\\t---\\n" &&
        ./get /rollouts | \
        jq --raw-output '.content | map([ .id, .name, (.createdAt / 1000 | todate), (.lastModifiedAt / 1000 | todate), .status , .totalTargets, .description ])[] | @tsv'
    ) | column -s '	' -t
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

    if [[ "$3" =~ -a|--all ]]; then
        groups=$(./get "/rollouts/$2/deploygroups" | jq --raw-output .content[].id)
    else
        groups="${*:3}"
    fi

    (
        printf "Name\\tStatus\\n---\\t---\\n" &&
        for group in $groups; do
            echo "# group $group"
            get_group "$2" "$group"
        done
    ) | column -s '	' -t
elif [[ "$1" == "delete" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for rollouts delete"
        exit 1
    fi

    ./delete "/rollouts/$2" | jq .
elif [[ "$1" == "list" ]]; then
    list_rollouts
else
    list_rollouts
fi
