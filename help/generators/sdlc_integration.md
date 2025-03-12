# Generators in the Software Development Life Cycle

This document maps how Amber generators integrate into the Software Development Life Cycle (SDLC), showing which phases each generator supports and their overall completion status.

## SDLC Phase: Planning & Requirements

During this phase, you gather requirements and plan the development approach.

| Generator | Relevance | Status |
|-----------|-----------|--------|
| None directly | Generators are implementation tools rather than planning tools | N/A |

## SDLC Phase: Design

During this phase, you design the system architecture, database schema, and overall structure.

| Generator | Relevance | Status |
|-----------|-----------|--------|
| Model Generator | Helps design data models and database schema | ✅ Complete |
| Migration Generator | Supports database schema design | ✅ Complete (as part of Model) |

## SDLC Phase: Implementation

During this phase, you build the actual application components.

| Generator | Relevance | Status |
|-----------|-----------|--------|
| Model Generator | Creates model files with validations and relationships | ✅ Complete |
| Controller Generator | Creates controller files with actions | ✅ Complete |
| Scaffold Generator | Creates full CRUD implementation for a resource | ✅ Complete |
| API Generator | Creates API endpoints for a resource | ✅ Complete |
| Mailer Generator | Creates email templates and mailer classes | ✅ Complete |
| Socket Generator | Creates WebSocket connection handlers | ✅ Complete |
| Channel Generator | Creates WebSocket channels for real-time features | ✅ Complete |
| Error Generator | Creates error handling templates | ❌ Not Implemented |

## SDLC Phase: Testing

During this phase, you test the application to ensure it meets requirements.

| Generator | Relevance | Status |
|-----------|-----------|--------|
| Model Generator | Creates model spec files | ✅ Complete |
| Controller Generator | Creates request spec files | ✅ Complete |
| API Generator | Creates request and model spec files | ✅ Complete |

## SDLC Phase: Deployment

During this phase, you deploy the application to production.

| Generator | Relevance | Status |
|-----------|-----------|--------|
| None directly | Deployment is handled by separate processes | N/A |

## SDLC Phase: Maintenance

During this phase, you maintain and enhance the application.

| Generator | Relevance | Status |
|-----------|-----------|--------|
| All Generators | Support adding new features and components | ✅ Complete |
| Migration Generator | Supports database schema evolution | ✅ Complete |

## Generator Workflow Integration

The generators are designed to be used in sequence to support a complete development workflow:

1. **Initial Setup**:
   - Use Model Generator to create data models
   - Use Migration Generator to set up database schema

2. **Building Features**:
   - For full-stack features: Use Scaffold Generator
   - For API endpoints: Use API Generator
   - For email notifications: Use Mailer Generator
   - For real-time features: Use Socket and Channel Generators

3. **Testing**:
   - Model and controller specs are generated automatically
   - Enhance with additional tests as needed

4. **Iteration**:
   - Use individual generators to extend functionality
   - Use Migration Generator to evolve the database schema

## Completion Status Overview

- **✅ Complete (8/9)**: Model, Controller, API, Scaffold, Mailer, Socket, Channel, Migration
- **❌ Not Implemented (1/9)**: Error Generator (should be part of base app template)

## Future Enhancements

- Integration with frontend framework generators
- Enhanced testing generators
- Deployment and infrastructure generators 