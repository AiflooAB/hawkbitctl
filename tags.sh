#!/bin/bash

if [[ "$1" == "create" ]]; then
    set -u

    jq --null-input \
        --arg name "$2" \
        --arg description "$3" \
        '[{ "name": $name, "description": $description }]' \
        | ./post /targettags | jq .
elif [[ "$1" == "delete" ]]; then
    set -u

    ./delete "/targettags/$2"
elif [[ "$1" == "list" ]] && [[ -n "$2" ]]; then
    set -u

    ./get "/targettags/$2/assigned" | jq .
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
else
    ./get /targettags | jq .
fi
