# Prompt format expectations

You should have received a prompt asking you to perform the initial application configuration with the following details:

- The name of the application

## Before getting started

1. Check for a github username in the shell. Query it yourself and remember it for the next step.
2. Check for an email address in the shell. Query it yourself and remember it for the next step.
3. Check if the user is on MacOS. If so, check that brew is installed.
4. Check if the user is on Linux. If so, check that the postgres client is installed.
5. Check that the `whoami` command returns the local username, if the user is on MacOS.

## Initial Application Configuration Instructions

1. Using the application name, update the `name` field in `shard.yml`.
2. Using the author's name and email address, update the `author` field in `shard.yml`.
3. Using the application name, update the name of the file in `src/agentc_app_template_oss.cr` to the application name, using snake case.
4. Update the `.amber.yml` file so that the `crystal build ./src/agentc_app_template_oss.cr -o bin/agentc_app_template_oss` command is using the newly updated file name from the previous step.
5. In the same `.amber.yml` file, update the `watch.run.run_commands` section so that it changes from `bin/agentc_app_template_oss` to the newly updated file name from the previous step.
6. Update the `config/database.yml` file so that the `db` field is the application name in snake case, followed by `_development`, `_test`, and `_production`.
7. Update the `config/database.yml` file so that the `user` field in the `default` section is the local username returned by the `whoami` command if the user is on MacOS, or the username `postgres` if the user is on Linux.
8. Run the `crystal build sam.cr` command and then run `./sam db:create && ./sam db:migrate && ./sam db:seed` to create the database, run migrations, and seed the database.
9. Update the `src/views/home/index.ecr` file so that the `<h2>` tag contains the application name in proper title case.


## Confirming Everthing Works

Run the `crystal build src/agentc_app_template_oss.cr -o bin/agentc_app_template_oss` command to make sure everything builds correctly. 

Now, run the `bin/agentc_app_template_oss` command to start the application and open the browser to `http://localhost:3000/` in the browser.

If the terminal output does not specify any errors running the application, you're all set!
