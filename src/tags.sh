#!/bin/bash

show_help() {
cat << EOF
Usage: hawkbitctl tags [<command>]
Manage target tags in hawkbit, including adding targets to them.

    -h, --help  display this help and exit

Subcommands, if <command> is omitted list will be used.

    list                            List all tags
    assigned <ID>                   Show targets assigned to tag ID
    create <NAME> <DESCRIPTION>     Crete a new tag
    delete <ID>                     Delete the tag with ID <ID>
    add <ID> <TARGET>...            Add TARGETs to tag ID
EOF
}

if [[ "$1" =~ -h|--help ]]; then
    show_help
    exit 0
elif [[ "$1" == "create" ]]; then
    set -u

    jq --null-input \
        --arg name "$2" \
        --arg description "$3" \
        '[{ "name": $name, "description": $description }]' \
        | ./post /targettags | jq .
elif [[ "$1" == "delete" ]]; then
    set -u

    ./delete "/targettags/$2"
elif [[ "$1" == "assigned" ]] && [[ -n "$2" ]]; then
    set -u
    tag_id="$2"

    get_page() {
        offset=$(( 50 * $1 ))
        resp=$(./get "/targettags/$tag_id/assigned?limit=50&offset=$offset")
        total="$(jq .total <<< "$resp")"
        size="$(jq .size <<< "$resp")"
        jq . <<< "$resp"

        if [ $(( offset + size )) -lt "$total" ]; then
            get_page $(( $1 + 1 ))
        fi
    }

    get_page 0

elif [[ "$1" == "add" ]] && [[ -n "$2" ]] && [[ -n "$3" ]]; then
    ids=("${@:3}")

    # Might work in jq 1.6
    # jq --null-input \
    #     --args "${ids[@]}" \
    #    'map({ controllerId: . })' 

    items=$(printf ',"%s"' "${ids[@]}")
    quoted="[${items:1}]"

    echo "$quoted" | jq 'map({ controllerId: . })' \
        | ./post "/targettags/$2/assigned" | jq .
elif [[ "$1" == "list" ]]; then
    ./get /targettags | jq .
else
    ./get /targettags | jq .
fi
