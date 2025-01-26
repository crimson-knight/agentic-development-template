# About Views

Views are files that are used to render HTML, JSON, or other content to the user.

Folder structure explanation:

- `api` folder holds views that belong to the `api` grouped routes, this is intended for API endpoints that return JSON.
- `public` folder holds views that belong to the `public` grouped routes
- `authenticated` folder holds views that belong to the `authenticated` grouped routes, this is intended for authenticated users who are interacting with the application.
- `static` folder holds views that belong to the `static` grouped routes
- `layouts` is a shared folder that holds common layouts and partials that are used across most views.

The sub folders must match the sub folder of the controller they belong to.
Example:

- `src/controllers/public/home_controller.cr` - This is the controller for the `public` grouped routes
- `src/views/public/home/index.html.ecr` - This is the view for the `public` grouped routes
