# Getting started

## Setup

### Environment

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

### netrc

You can also configure your credentials with the help of `~/.netrc` (see
`curl(1) --netrc` for more information)

`~/.netrc` might look like this:

    machine hawkbit.example.com login admin password hunter2

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

## Development

For local development, set `HAWKBITCTL_SOURCEDIR="$PWD/src"`

    export HAWKBITCTL_SOURCEDIR="$PWD/src"
