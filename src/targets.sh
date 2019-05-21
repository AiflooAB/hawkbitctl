#!/bin/bash

show_help() {
cat << EOF
Usage: hawkbitctl targets [<command>]
Manage targets in hawkbit.

Note that tag assignment happens with ./tags.sh

    -h, --help  display this help and exit
    --filter    Filter the output (only supported by list)
                More information:
                https://www.eclipse.org/hawkbit/ui/#how-to-filter
                Example: attribute.mac_address==de:ad:*

Subcommands, if <command> is omitted list will be used.

    list                List all tags
    show <ID>           Show details about target ID
    attributes <ID>     Show all attributes for target ID
    delete <ID>         Delete target ID
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
    if [[ "$latest_action" == "null" ]]; then
        exit 0
    fi
    ./get "/targets/$2/actions/$latest_action/status" | \
        jq --raw-output '.content | map([ .type, (.reportedAt/1000 | todate), (.messages | join(" | "))])[] | @tsv' | \
        column -s '	' -t
elif [[ "$1" == "attributes" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for attributes"
        exit 1
    fi
    ./get "/targets/$2/attributes" | \
        jq --raw-output '. | to_entries[] | [ .key, .value ] | @tsv' | \
        column -s '	' -t
elif [[ "$1" == "delete" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for attributes"
        exit 1
    fi
    ./delete "/targets/$2"
elif [[ "$1" == "list" ]]; then
    if [[ "$2" == "--filter" ]]; then
        query="?q=$3"
    fi
    ./get "/targets${query:-}" | jq .
else
    ./get /targets | jq .
fi
