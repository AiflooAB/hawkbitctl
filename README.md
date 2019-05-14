# Getting started

Specify the admin password by running the following two commands

```bash
export PASSWORD
read -s -p $'Enter your password:\n' -r PASSWORD
```

## Switching environment

The variable `API_HOST` contains the path to hawkbit, for example:

```bash
export API_HOST=https://hawkbit.example.com
```

Remember that you will have to reenter your password whenever you switch `API_HOST`
