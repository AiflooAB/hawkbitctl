#!/bin/bash

DIR="${HAWKBITCTL_SOURCEDIR:-/usr/lib/hawkbitctl}"

show_help() {
cat << EOF
Usage: hawkbitctl distributionsets [<command>] [OPTION]...

Manage distribution sets in hawkbit.

    -h, --help  display this help and exit

Subcommands, if <command> is omitted list will be used.

    list                                                        List all rollouts
    show <DISTRIBUTION>                                         Show details about a specific distribution set
    delete <DISTRIBUTION>...                                    Delete one or more distribution sets
    create <NAME> <VERSION> <TYPE> <DESCRIPTION> [MODULES]...   Create a distribution set with zero or more software modules
EOF
}

list_distributions() {
    (
    printf "ID\\tName\\tVersion\\n---\\t---\\t---\\n" &&
    "$DIR/get" /distributionsets | \
        jq --raw-output '.content | map([ .id, .name, .version ])[] | @tsv'
    ) | column -s '	' -t
}

show_modules() {
    modules=$(jq .modules <<< "$1")
    (
    printf "ID\\tName\\tVersion\\n---\\t---\\t---\\n" &&
        jq --raw-output 'map([ .id, .name, .version ])[] | @tsv' <<<"$modules"
    ) | column -s '	' -t
}

show_distribution() {
    module_info=$("$DIR/get" "/distributionsets/$1")
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
Complete:         $(jq --raw-output .complete                       <<< "$module_info")
Description:      $(jq --raw-output .description                    <<< "$module_info" \
                    | awk 'NR == 1 { print; next} { printf("%18s", " "); print; }')
Modules:          $(show_modules "$module_info" \
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

    show_distribution  "$2"
elif [[ "$1" == "list" ]]; then
    list_distributions
elif [[ "$1" == "create" ]]; then
    if [[ -z $2 ]] || [[ -z $3 ]] || [[ -z $4 ]] || [[ -z $5 ]]; then
        echo >&2 "Create requires <NAME> <VERSION> <TYPE> <DESCRIPTION> [MODULES]..."
        exit 1
    fi
    name=$2
    version=$3
    dist_type=$4
    desc=$5
    shift 5
    modules="[$(IFS=,; echo "$*")]"
    trap 'rm -f $tmpfile' EXIT
    tmpfile=$(mktemp tmp.hawkbitctl.XXXXXXX)
    http_status=$(jq --null-input \
        --arg name "$name" \
        --arg version "$version" \
        --arg type "$dist_type" \
        --arg description "$desc" \
        --argjson modules "$modules" \
        '[{ "name": $name, "version": $version, "type": $type, "description", $description, "modules": $modules | map({ "id": . }) }]' \
        | "$DIR/post" /distributionsets "$tmpfile")
    if (( http_status >= 200 && http_status < 300 )); then
        jq . < "$tmpfile"
    else
        echo >&2 "Failed to create software module:"
        jq --raw-output >&2 .message < "$tmpfile"
        exit 1
    fi
elif [[ "$1" == "delete" ]]; then
    if [[ -z $2 ]]; then
        echo >&2 "distributionsets delete requires at least one <ID>"
        exit 1
    fi

    shift 1
    for module in "$@"; do
        "$DIR/delete" "/distributionsets/$module" | jq .
    done
else
    list_distributions
    exit 0
fi
