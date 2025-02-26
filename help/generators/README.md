# Amber Generators

The generator prompts here serve to replace the same functionality you would see in the Amber CLI tool with an agentic version.

## Generator Functionality Checklist

### Scaffold Generator
- [x] Create route with `resources`
- [x] Create model
- [x] Create migration for model
- [x] Update nav
- [x] Create CRUD views with form partial
- [x] Create model spec
Status: Completed - Documentation exists in `help/generators/create_a_scaffold.md`

### API Generator
- [x] Create route
- [x] Create model
- [x] Create controller in API pipes
- [x] Create request spec
- [x] Create model spec
Status: Completed - Documentation exists in `help/generators/create_an_api_endpoint.md`

### Model Generator
- [x] Create model
- [x] Create migration
- [x] Create model spec
Status: Completed - Documentation exists in `help/generators/create_a_model.md`

### Controller Generator
- [x] Create route
- [x] Create controller
- [x] Create request spec
Status: Completed - Documentation exists in `help/generators/create_a_controller_default.md`

### Migration Generator
- [x] Create single migration file
Status: Covered in model documentation, with specific examples in other generator docs

### Mailer Generator
- [x] Create mailer file in src/mailers
- [x] Create view in /src/views/mailers for html
- [x] Create view in /src/views/mailers for txt
Status: Completed - Documentation exists in `help/generators/create_a_mailer.md`

### Socket Generator
- [x] Create single socket file under `src/sockets/`
Status: Completed - Documentation exists in `help/generators/create_a_socket.md`

### Channel Generator
- [x] Create single test channel under `src/channels/`
Status: Completed - Documentation exists in `help/generators/create_a_channel.md`

### Error Generator
- [ ] Create error handling templates (should be part of base app template)
Status: Not implemented as standalone generator

