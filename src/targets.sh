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
    --list      List available actions (only supported by actions)
    --action    Show logs for a specific action (only supported by actions)

Subcommands, if <command> is omitted list will be used.

    list                List all tags
    show <ID>           Show details about target ID
    attributes <ID>     Show all attributes for target ID
    delete <ID>         Delete target ID
    actions <ID>        Show the logs for the latest action for a target
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
    target="$2"
    if [[ "$3" == "--list" ]]; then
        (
        printf "ID\\tCreated at\\tLast modified at\\tType\\tStatus\\n"
        ./get "/targets/$target/actions" | \
            jq --raw-output \
            '.content | map([.id, (.createdAt/1000 | todate), (.lastModifiedAt/1000 | todate), .type, .status])[] | @tsv' | \
            column -s ' ' -t
        ) | column -s '	' -t
        exit 0
    fi

    if [[ "$3" == "--action" ]]; then
        action="$4";
    else
        action=$(./get "/targets/$target/actions" | jq .content[0].id)
        if [[ "$action" == "null" ]]; then
            exit 0
        fi
    fi
    ./get "/targets/$target/actions/$action/status" | \
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
    (
        printf "ID\\tName\\tController ID\\tLast poll\\tStatus\\tDescription\\n---\\t---\\t---\\t---\\t---\\t---\\n" &&
        ./get "/targets${query:-}" | \
        jq --raw-output '.content | map([ .name, .controllerId, (if .lastControllerRequestAt then (.lastControllerRequestAt / 1000 | todate) else "-" end), .updateStatus, .description])[] | @tsv'
    ) | column -s '	' -t
else
    ./"$0" list
fi
