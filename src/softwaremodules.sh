#!/bin/bash

DIR="${HAWKBITCTL_SOURCEDIR:-/usr/lib/hawkbitctl}"

show_help() {
cat << EOF
Usage: hawkbitctl softawremodules [<command>] [OPTION]...

Manage software modules in hawkbit.

    -h, --help  display this help and exit

Subcommands, if <command> is omitted list will be used.

    list                                            List all software modules
    show <MODULE>                                   Show details about a specific software module
    delete <MODULE>...                              Delete one or more software modules
    create <NAME> <VERSION> <TYPE> [DESCRIPTION]    Create a new software module
    upload <MODULE> <ARTIFACT>                      Upload artifact to software module
EOF
}

list_modules() {
    (
    printf "ID\\tName\\tVersion\\n---\\t---\\t---\\n" && 
    "$DIR/get" /softwaremodules | \
        jq --raw-output '.content | map([ .id, .name, .version ])[] | @tsv'
    ) | column -s '	' -t
}

show_module() {
    module_info=$("$DIR/get" "/softwaremodules/$1")
    cat <<EOF
Name:             $(jq --raw-output .name                           <<< "$module_info")
Version:          $(jq --raw-output .version                        <<< "$module_info")
Created at:       $(jq --raw-output '.createdAt/1000 | todate'      <<< "$module_info")
Created by:       $(jq --raw-output .createdBy                      <<< "$module_info")
Last modified at: $(jq --raw-output '.lastModifiedAt/1000 | todate' <<< "$module_info")
Last Modified by: $(jq --raw-output .lastModifiedBy                 <<< "$module_info")
Type:             $(jq --raw-output .type                           <<< "$module_info")
Vendor:           $(jq --raw-output .vendor                         <<< "$module_info")
Deleted:          $(jq --raw-output .deleted                        <<< "$module_info")
Description:      $(jq --raw-output .description                    <<< "$module_info" \
                    | awk 'NR == 1 { print; next} { printf("%18s", " "); print; }')
EOF
}

if [[ "$1" =~ -h|--help ]]; then
    show_help
    exit 0
elif [[ "$1" == "show" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for softwaremodules show"
        exit 1
    fi

    show_module  "$2"
elif [[ "$1" == "list" ]]; then
    list_modules
elif [[ "$1" == "create" ]]; then
    if [[ -z $2 ]] || [[ -z $3 ]] || [[ -z $4 ]]; then
        echo >&2 "Create requires <NAME> <VERSION> <TYPE>"
        exit 1
    fi
    trap 'rm -f $tmpfile' EXIT
    tmpfile=$(mktemp tmp.hawkbitctl.XXXXXXX)
    http_status=$(jq --null-input \
        --arg name "$2" \
        --arg version "$3" \
        --arg type "$4" \
        --arg description "$5" \
        '[{ "name": $name, "version": $version, "type": $type, "description", $description, "vendor": "" }]' \
        | "$DIR/post" /softwaremodules "$tmpfile")

    if (( http_status >= 200 && http_status < 300 )); then
        jq . < "$tmpfile"
    else
        echo >&2 "Failed to create software module:"
        jq --raw-output >&2 .message < "$tmpfile"
        exit 1
    fi
elif [[ "$1" == "upload" ]]; then
    shift
    if [[ -z "$1" ]] || [[ -z $2 ]]; then
        echo >&2 "Upload requires <MODULE> <ARTIFACT>"
        exit 1
    fi
    moduleid="$1"
    artifact="$2"

    trap 'rm -f $tmpfile' EXIT
    tmpfile=$(mktemp tmp.hawkbitctl.XXXXXXX)
    http_status=$("$DIR/upload" "/softwaremodules/$moduleid/artifacts" "$artifact" "$(sha1sum "$artifact" | awk '{ print $1 }')" "$tmpfile")

    if (( http_status >= 200 && http_status < 300 )); then
        jq . < "$tmpfile"
    else
        echo >&2 "Failed to create software module:"
        jq --raw-output >&2 .message < "$tmpfile"
        exit 1
    fi

elif [[ "$1"  == "delete" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "<ID> missing for softwaremodules delete"
        exit 1
    fi

    shift 1
    for module in "$@"; do
        "$DIR/delete" "/softwaremodules/$module" | jq .
    done
else
    list_modules
fi
