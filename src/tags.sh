#!/bin/bash

DIR="${HAWKBITCTL_SOURCEDIR:-/usr/lib/hawkbitctl}"

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
    unassign <ID> <TARGET>...       Remove TARGETs from tag ID
EOF
}

if [[ "$1" =~ -h|--help ]]; then
    show_help
    exit 0
elif [[ "$1" == "create" ]]; then
    set -u

    trap 'rm -f $tmpfile' EXIT
    tmpfile=$(mktemp tmp.hawkbitctl.XXXXXXX)
    http_status=$(jq --null-input \
        --arg name "$2" \
        --arg description "$3" \
        '[{ "name": $name, "description": $description }]' \
        | "$DIR/post" /targettags "$tmpfile")

    if (( http_status >= 200 && http_status < 300 )); then
        jq . < "$tmpfile"
    else
        echo >&2 "Failed to create tag:"
        jq --raw-output >&2 .message < "$tmpfile"
        exit 1
    fi
elif [[ "$1" == "delete" ]]; then
    set -u

    "$DIR/delete" "/targettags/$2"
elif [[ "$1" == "assigned" ]] && [[ -n "$2" ]]; then
    set -u

    "$DIR/get" "/targettags/$2/assigned" 0
elif [[ "$1" == "add" ]] && [[ -n "$2" ]] && [[ -n "$3" ]]; then
    ids=("${@:3}")

    # Might work in jq 1.6
    # jq --null-input \
    #     --args "${ids[@]}" \
    #    'map({ controllerId: . })' 

    items=$(printf ',"%s"' "${ids[@]}")
    quoted="[${items:1}]"

    trap 'rm -f $tmpfile' EXIT
    tmpfile=$(mktemp tmp.hawkbitctl.XXXXXXX)
    http_status=$(echo "$quoted" | jq 'map({ controllerId: . })' \
        | "$DIR/post" "/targettags/$2/assigned" "$tmpfile")

    if (( http_status >= 200 && http_status < 300 )); then
        jq . < "$tmpfile"
    else
        echo >&2 "Failed to add targets to tag $2:"
        jq --raw-output >&2 .message < "$tmpfile"
        exit 1
    fi
elif [[ "$1" == "list" ]]; then
    "$DIR/get" /targettags | jq .
elif [[ "$1" == "unassign" ]]; then
    set -u
    target="$2"
    shift 2
    for controller in "$@"; do
        ./delete "/targettags/$target/assigned/$controller"
    done
else
    "$DIR/get" /targettags | jq .
fi
