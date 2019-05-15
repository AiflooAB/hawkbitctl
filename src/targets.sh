#!/bin/bash

show_help() {
cat << EOF
Usage: hawkbitctl targets [<command>]
Manage targets in hawkbit.

Note that tag assignment happens with ./tags.sh

    -h, --help  display this help and exit

Subcommands, if <command> is omitted list will be used.

    list        List all tags
    show <ID>   Show details about target ID
EOF
}

if [[ "$1" =~ -h|--help ]]; then
    show_help
    exit 0
elif [[ "$1" == "show" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for show"
        exit 1
    fi
    ./get "/targets/$2" | jq .
elif [[ "$1" == "actions" ]]; then
    latest_action=$(./get "/targets/$2/actions" | jq .content[0].id)
    # ./get "/targets/$2/actions/$latest_action/status" | jq --raw-output '.content | map(.type + "\t@\t" + (.reportedAt | tostring) + "\t" + (.messages | join(" | ")))[]'
    ./get "/targets/$2/actions/$latest_action/status" | jq --raw-output '.content | map([ .type, (.reportedAt/1000 | todate), (.messages | join(" | "))])[] | @tsv' | column -s '	' -t
elif [[ "$1" == "list" ]]; then
    ./get /targets | jq .
else
    ./get /targets | jq .
fi
