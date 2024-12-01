# Prompt format expectations

You should have received a prompt asking you to perform the initial application configuration with the following details:

- The name of the application

## Before getting started

1. Check for a github username in the shell. Query it yourself and remember it for the next step.
2. Check for an email address in the shell. Query it yourself and remember it for the next step.

## Initial Application Configuration Instructions

1. Using the application name, update the `name` field in `shard.yml`.
2. Using the author's name and email address, update the `author` field in `shard.yml`.
3. Using the application name, update the name of the file in `src/agentc_app_template_oss.cr` to the application name, using snake case.
4. Update the `.amber.yml` file so that the `crystal build ./src/agentc_app_template_oss.cr -o bin/agentc_app_template_oss` command is using the newly updated file name from the previous step.
5. In the same `.amber.yml` file, update the `watch.run.run_commands` section so that it changes from `bin/agentc_app_template_oss` to the newly updated file name from the previous step.

## Confirming Everthing Works

Run the `crystal build src/agentc_app_template_oss.cr -o bin/agentc_app_template_oss` command to make sure everything builds correctly. If the terminal output does not specify any errors running the application, you're all set!
