#!/bin/bash

if [ -z "$PASSWORD" ]; then
    echo >&2 "Specify the admin password by running the following two commands"
    echo >&2 "export PASSWORD"
    # shellcheck disable=SC1117 disable=SC2028
    echo >&2 "read -s -p $'Enter your password:\n' -r PASSWORD"
    exit 1
fi

if [ -z "$API_HOST" ]; then
    echo >&2 "You need to set the API_HOST variable to point to your hawkbit instance:"
    echo >&2 "export API_HOST=https://hawkbit.example.com"
    exit 1
fi

# shellcheck disable=SC2034
API_URL="$API_HOST/rest/v1"
