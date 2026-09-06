# agentc_app_template_oss Tasks

## Outstanding Issues

### Test Suite Issues
- [ ] Fix `:web` pipeline missing in test environment (KeyError in spec/request_helper.cr)
- [ ] 47 tests failing due to missing pipeline registration
- [ ] Review spec/request_helper.cr line 24 for proper pipeline setup

### Migration Work (Branch: migrate-to-grant-orm)
- [x] Remove amber CLI target from shard.yml
- [x] Change .amber.yml model from jennifer to grant
- [x] Compilation verified working
- [ ] Fix test suite to pass
- [ ] Commit and push changes

### Documentation
- [ ] Validate getting started guide works end-to-end
- [ ] Create end-to-end test script

## Completed
- Changed ORM from Jennifer to Grant
- Removed old amber CLI target
- Verified compilation succeeds
