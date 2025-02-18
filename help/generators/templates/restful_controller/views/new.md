# New View Template & Instructions

1. Using the template below, create the new view in the `src/views/{namespace}/#{controller_name}` directory with the file name `new.ecr`.

```crystal
# src/views/{namespace}/#{controller_name}/new.ecr
<h1>New {{singular_resource_name}}</h1>

<%= render(partial: "_form.ecr") %>
```