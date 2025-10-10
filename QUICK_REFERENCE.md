# Quick Reference Guide - Agentic Template Upgrade

## How to Use This Implementation System

### For Immediate Context Recovery

If you need to quickly recover where you are in the implementation:

1. **Read**: `IMPLEMENTATION_TRACKER.md` - Shows overall progress and current phase
2. **Query Chroma**: Use collection `agentic_template_upgrade_tracker`
3. **Check Todos**: Review active todo list
4. **Resume**: Continue from last unchecked item in current phase

### Chroma Collection Structure

**Collection Name:** `agentic_template_upgrade_tracker`

**Query Examples:**
```crystal
# Get phase overview
chroma_query_documents(
  collection_name: "agentic_template_upgrade_tracker",
  query_texts: ["phase 1 overview"],
  n_results: 1
)

# Get configuration details
chroma_query_documents(
  collection_name: "agentic_template_upgrade_tracker",
  query_texts: ["configuration files"],
  n_results: 3
)

# Get example model features
chroma_query_documents(
  collection_name: "agentic_template_upgrade_tracker",
  query_texts: ["user model features"],
  n_results: 1
)
```

---

## Phase Quick Reference

### Phase 1: Directory Structure (24 doc files + 11 help files)
**Action:** Create empty directory structure
**Time Estimate:** 10 minutes
**Priority:** HIGH
**Blockers:** None

### Phase 2: Documentation Extraction
**Action:** Extract content from source READMEs, transform for Amber
**Time Estimate:** 2-3 hours
**Priority:** HIGH
**Blockers:** Requires Phase 1 complete

### Phase 3: Configuration & Examples (11 files)
**Action:** Create working config files and comprehensive examples
**Time Estimate:** 2-3 hours
**Priority:** HIGH
**Blockers:** None (can run parallel with Phase 1)

### Phase 4: AI Instruction Files (4 files)
**Action:** Create detailed help files for AI agents
**Time Estimate:** 1-2 hours
**Priority:** MEDIUM
**Blockers:** Requires Phase 3 examples complete

### Phase 5: Implementation Checklist (10 steps)
**Action:** Execute systematic integration following checklist
**Time Estimate:** 1 hour (verification)
**Priority:** HIGH
**Blockers:** Requires Phases 1-4 complete

### Phase 6: Documentation Validation (20 files)
**Action:** Ensure all documentation meets content requirements
**Time Estimate:** 1-2 hours
**Priority:** MEDIUM
**Blockers:** Requires Phase 2 complete

---

## Critical Files to Create (Priority Order)

### Tier 1 - Foundation (Must Create First)
1. `config/initializers/grant.cr`
2. `config/initializers/gemma.cr`
3. `config/initializers/asset_pipeline.cr`
4. `config/database.yml`
5. `.env.example`
6. `shard.yml` (update)

### Tier 2 - Core Examples (Create Second)
7. `src/models/user.cr`
8. `src/controllers/users_controller.cr`
9. `src/views/users/new.ecr`
10. `src/javascript/controllers/user_form_controller.js`
11. `src/views/layouts/application.ecr` (update)

### Tier 3 - Documentation (Create Third)
12. `docs/README.md`
13. `docs/grant/README.md`
14. `docs/gemma/README.md`
15. `docs/asset_pipeline/README.md`

### Tier 4 - Help Files (Create Fourth)
16. `src/models/i_want_to_create_a_model.md`
17. `src/controllers/i_want_to_create_a_controller.md`
18. `help/gemma/help_with_file_uploads.md`
19. `help/asset_pipeline/help_with_javascript_setup.md`

---

## Template Snippets for Quick Copy-Paste

### Grant Model Basic Structure
```crystal
require "grant"

class ModelName < Grant::Base
  connection pg
  table table_name

  column id : Int64, primary: true
  # Add columns here

  timestamps
end
```

### Gemma File Attachment
```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column avatar_data : JSON::Any?
  has_one_attached :avatar

  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png"]
end
```

### Controller File Upload Handling
```crystal
def create
  user = User.new(user_params)

  if avatar = params.files["avatar"]?
    user.avatar = avatar.file
  end

  if user.save
    redirect_to "/users/#{user.id}"
  else
    render "new.ecr"
  end
end
```

### Stimulus Controller Basic
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    console.log("Controller connected")
  }

  action() {
    // Your code here
  }
}
```

---

## File Count Summary

| Category | Count | Status |
|----------|-------|--------|
| Configuration Files | 6 | 0/6 |
| Example Files | 5 | 0/5 |
| Grant Documentation | 8 | 0/8 |
| Gemma Documentation | 6 | 0/6 |
| Asset Pipeline Documentation | 6 | 0/6 |
| Integration Documentation | 3 | 0/3 |
| Grant Help Files | 5 | 0/5 |
| Gemma Help Files | 3 | 0/3 |
| Asset Pipeline Help Files | 3 | 0/3 |
| AI Instruction Files | 4 | 0/4 |
| Migration Templates | 2 | 0/2 |
| Testing Examples | 3 | 0/3 |
| **TOTAL** | **54** | **0/54 (0%)** |

---

## Recommended Execution Strategy

### Strategy A: Sequential (Safest)
1. Complete Phase 1 entirely
2. Complete Phase 3 entirely
3. Complete Phase 2 entirely
4. Complete Phase 4 entirely
5. Execute Phase 5
6. Validate Phase 6

**Time Estimate:** 8-10 hours
**Risk:** Low
**Best For:** First-time implementation

### Strategy B: Parallel (Faster)
1. Start Phase 1 + Phase 3 simultaneously
2. While Phase 2 documentation is being written, complete Phase 3
3. Use completed Phase 3 examples to inform Phase 4
4. Execute Phase 5 and 6 together

**Time Estimate:** 6-8 hours
**Risk:** Medium
**Best For:** Experienced with context management

### Strategy C: Hybrid (Recommended)
1. **Day 1 Morning:** Phase 1 (directory structure) + Phase 3 (config files)
2. **Day 1 Afternoon:** Phase 3 (examples) + start Phase 2 (Grant docs)
3. **Day 2 Morning:** Complete Phase 2 (all docs) + Phase 4 (help files)
4. **Day 2 Afternoon:** Phase 5 (checklist execution) + Phase 6 (validation)

**Time Estimate:** 2 days (4-5 hours each)
**Risk:** Low-Medium
**Best For:** This project

---

## Common Pitfall Prevention

### Issue: Lost Context During Long Implementation
**Solution:** Update IMPLEMENTATION_TRACKER.md after every 5 files created

### Issue: Missing Dependencies Between Files
**Solution:** Always create configuration files before examples

### Issue: Inconsistent Code Style
**Solution:** Reference existing files in src/models/ and src/controllers/

### Issue: Incomplete Documentation
**Solution:** Use Phase 6 checklist as you write each doc file

### Issue: Chroma Memory Not Helping
**Solution:** Query with specific terms like "configuration details" or "user model features"

---

## Emergency Recovery Procedure

If you completely lose context:

1. **Read** `IMPLEMENTATION_TRACKER.md` - Check "Overall Progress" table
2. **Query Chroma**: `chroma_query_documents("what was I working on", n_results: 5)`
3. **List Files**: `ls -la docs/ help/ config/initializers/` to see what exists
4. **Read Last File**: Read the most recently modified file to see what you were doing
5. **Resume**: Continue from first unchecked item in current phase

---

## Quality Checklist (Run Before Marking Complete)

For each file created:
- [ ] Valid Crystal/JavaScript syntax (no errors)
- [ ] Follows project code style
- [ ] Includes comments for complex logic
- [ ] Has proper error handling
- [ ] Matches specifications in overall_upgrade_plan.md
- [ ] Cross-referenced in IMPLEMENTATION_TRACKER.md
- [ ] Stored checkpoint in Chroma if milestone

---

## Contact Points

**Source Repositories:**
- Grant: https://github.com/crimson-knight/grant
- Gemma: https://github.com/crimson-knight/gemma
- Asset Pipeline: https://github.com/amberframework/asset_pipeline

**Reference Documentation:**
- Overall Plan: `/Users/crimsonknight/agentc_app_template_oss/overall_upgrade_plan.md`
- Implementation Tracker: `/Users/crimsonknight/agentc_app_template_oss/IMPLEMENTATION_TRACKER.md`
- This Quick Reference: `/Users/crimsonknight/agentc_app_template_oss/QUICK_REFERENCE.md`

---

**Last Updated:** 2025-10-10
