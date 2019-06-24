# Getting started

## Setup

Specify the admin password by running the following two commands

```bash
export PASSWORD
read -s -p $'Enter your password:\n' -r PASSWORD
```

The variable `API_HOST` contains the path to hawkbit, for example:

```bash
export API_HOST=https://hawkbit.example.com
```

Remember that you will have to reenter your password whenever you switch `API_HOST`

## Usage

```
Usage: hawkbitctl [<command>] [<args>]
A simple CLI for managing hawkbit

    -h, --help  display this help and exit

Subcommands, for more information for any subcommand use:
hawkbitctl <command> --help

    tags        Manage target tags
    targets     Manage targets
    rollouts    Manage rollouts
```
