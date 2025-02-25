# Amber Generators

The generator prompts here serve to replace the same funcitonality you would see in the Amber CLI tool with an agentic version.

The general generator functions are as follows:

- scaffold
    1. Creates a route with `resources`, creates a model, creates the migration for the model, it updates the nav, it creates CRUD views, with a form partial, and a model spec

- api
    1. Creates a route, a model, and a controller, in the API pipes, a request spec, and a model spec

- model
    1. Creates a model, a migration and a model spec

- controller
    1. Creates a route, a controller, and a request spec

- migration
    1. Creates a single migration file named after whatever is provided

- mailer
    1. Creates a mailer file in src/mailers, a view in /src/views/mailers for html and txt 

- socket
    1. Creates a single socket file under `src/sockets/`

- channel
    1. Creates a single test channel under `src/channels/`

- error (should just be part of the base app template to make customization easier)

