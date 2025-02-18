# Routes Template & Instructions

1. The file contents should follow the template, where everything in the `{{}}` should be replaced with the appropriate values as they are described from the notes file:

```crystal
  routes :web do
    # example of a resource route
    resources "/{{pluralized_resource_name}}", {{controller_name}}Controller
  end
```

2. Rules:

 - All controllers are namespaced to either `Authenticated` or `Public` depending on the route grouping or the action needing to be taken.
 - If you are creating a RESTful controller, use the `resources` method to create the route.
 - If you are creating a non-RESTful controller, use the `get`, `post`, `put`, `patch`, or `delete` method to create the route.
 - If you are creating a route that must be restricted to authenticated users, use the `auth` route grouping.
 - If you are creating a route that must be restricted to unauthenticated users, use the `public` route grouping.
 