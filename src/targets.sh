#!/bin/bash

DIR="${HAWKBITCTL_SOURCEDIR:-/usr/lib/hawkbitctl}"

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

    list                    List all tags
    show <ID>               Show details about target ID
    attributes <ID>         Show all attributes for target ID
    delete <ID>             Delete target ID
    actions <ID>            Show the logs for the latest action for a target
    assignDS <TARGET> <DS>  Assign the distribution set with id DS to target with id TARGET
EOF
}

list_targets() {
    if [[ "$1" == "--filter" ]]; then
        query="?q=$2"
    fi
    (
        printf "ID\\tName\\tController ID\\tLast poll\\tStatus\\tDescription\\n---\\t---\\t---\\t---\\t---\\t---\\n" &&
        "$DIR/get" "/targets${query:-}" | \
        jq --raw-output '.content | map([ .name, .controllerId, (if .lastControllerRequestAt then (.lastControllerRequestAt / 1000 | todate) else "-" end), .updateStatus, .description])[] | @tsv'
    ) | column -s '	' -t
}

if [[ "$1" =~ -h|--help ]]; then
    show_help
    exit 0
elif [[ "$1" == "show" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for show"
        exit 1
    fi
    "$DIR/get" "/targets/$2" | jq .
elif [[ "$1" == "actions" ]]; then
    target="$2"
    if [[ "$3" == "--list" ]]; then
        (
        printf "ID\\tCreated at\\tLast modified at\\tType\\tStatus\\n"
        "$DIR/get" "/targets/$target/actions" | \
            jq --raw-output \
            '.content | map([.id, (.createdAt/1000 | todate), (.lastModifiedAt/1000 | todate), .type, .status])[] | @tsv' | \
            column -s ' ' -t
        ) | column -s '	' -t
        exit 0
    fi

    if [[ "$3" == "--action" ]]; then
        action="$4";
    else
        action=$("$DIR/get" "/targets/$target/actions" | jq .content[0].id)
        if [[ "$action" == "null" ]]; then
            exit 0
        fi
    fi
    "$DIR/get" "/targets/$target/actions/$action/status" | \
        jq --raw-output '.content | map([ .type, (.reportedAt/1000 | todate), (.messages | join(" | "))])[] | @tsv' | \
        column -s '	' -t
elif [[ "$1" == "attributes" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for attributes"
        exit 1
    fi
    "$DIR/get" "/targets/$2/attributes" | \
        jq --raw-output '. | to_entries[] | [ .key, .value ] | @tsv' | \
        column -s '	' -t
elif [[ "$1" == "assignDS" ]]; then
    if [[ -z $2 ]] || [[ -z $3 ]]; then
        echo >&2 "Assigne distribution requires <TARGET> <DS>"
        exit 1
    fi
    trap 'rm -f $tmpfile' EXIT
    tmpfile=$(mktemp tmp.hawkbitctl.XXXXXXX)
    http_status=$(jq --null-input \
        --arg id "$3" \
        '[{ "id": $id }]' \
        | "$DIR/post" "/targets/$2/assignedDS" "$tmpfile")
    if (( http_status >= 200 && http_status < 300 )); then
        jq . < "$tmpfile"
    else
        echo >&2 "Failed to create software module:"
        jq --raw-output >&2 .message < "$tmpfile"
        exit 1
    fi
elif [[ "$1" == "delete" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for attributes"
        exit 1
    fi
    "$DIR/delete" "/targets/$2"
elif [[ "$1" == "list" ]]; then
    shift
    list_targets "$@"
else
    list_targets "$@"
fi
