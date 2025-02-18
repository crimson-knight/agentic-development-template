# Edit View Template & Instructions

1. Using the notes file, remind yourself of the attributes of the resource.

2. Using the template below, create the edit view in the `src/views/{namespace}/#{controller_name}` directory with the file name `edit.ecr`.

```crystal
# src/views/#{controller_name}/edit.ecr
<h1>Edit {{singular_resource_name}}</h1>

<%= render(partial: "_form.ecr") %>
```