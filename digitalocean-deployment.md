# DigitalOcean App Platform Configuration

This document provides the configuration needed to deploy this Crystal/Amber application on DigitalOcean App Platform.

## App Platform Configuration

When creating your app on DigitalOcean, use this configuration:

### Web Service Configuration
```yaml
name: web
github:
  repo: your-username/your-repo
  branch: main
  deploy_on_push: true
dockerfile_path: Dockerfile
run_command: ./agentc_app_template_oss
envs:
  - key: AMBER_ENV
    value: production
    scope: RUN_TIME
  - key: PORT
    value: "3000"
    scope: RUN_TIME
  - key: DATABASE_URL
    value: ${your-db-name.DATABASE_URL}
    scope: RUN_TIME
instance_size_slug: apps-s-1vcpu-1gb
instance_count: 1
http_port: 3000
health_check:
  initial_delay_seconds: 30
  period_seconds: 10
  timeout_seconds: 5
  success_threshold: 1
  failure_threshold: 3
  http_path: "/"
```

### Migration Job Configuration (PRE_DEPLOY)
```yaml
name: migrate
github:
  repo: your-username/your-repo
  branch: main
  deploy_on_push: true
dockerfile_path: Dockerfile
run_command: ./migrate.sh
envs:
  - key: AMBER_ENV
    value: production
    scope: RUN_TIME
  - key: APP_ENV
    value: production
    scope: RUN_TIME
  - key: DATABASE_URL
    value: ${your-db-name.DATABASE_URL}
    scope: RUN_TIME
instance_size_slug: apps-s-1vcpu-1gb
instance_count: 1
kind: PRE_DEPLOY
```

### Database Configuration
```yaml
name: your-db-name
engine: PG
version: "17"
```

## Deployment Flow

With these changes, the deployment will work as follows:

1. **Build Phase:** Docker builds the application with all dependencies
2. **PRE_DEPLOY Job:** `migrate.sh` runs database migrations and exits
3. **Web Service:** Application starts with `./agentc_app_template_oss` and runs continuously
4. **Health Check:** DigitalOcean checks the `/` endpoint on port 3000

## Key Features

- **Reliable Builds:** SQLite dependency prevents compilation failures
- **Version Compatibility:** PostgreSQL 17 client prevents version mismatch errors
- **Proper Separation:** Migrations run once before deployment, not on every restart
- **External Access:** Host binding allows health checks and external connections
- **Clean Deployment:** No blocking scripts that prevent deployment completion

## Troubleshooting

### Common Issues and Solutions

1. **Build fails with shard compilation errors:** Ensure `sqlite-dev` is in build dependencies
2. **Health check fails:** Verify host binding is set to `0.0.0.0` in `config/settings.cr`
3. **pg_dump version mismatch:** Use PostgreSQL 17 client from Alpine edge repository
4. **Deployment hangs:** Ensure CMD is removed from Dockerfile and scripts exit properly
5. **Migration failures:** Check that `migrate.sh` has proper error handling and environment variables

## Environment Variables

The following environment variables are automatically set by DigitalOcean App Platform:

- `DATABASE_URL`: Connection string for the PostgreSQL database
- `PORT`: Port number for the web service (3000)
- `AMBER_ENV`: Set to "production"
- `APP_ENV`: Set to "production"

## Next Steps

1. Create your app on DigitalOcean App Platform
2. Connect your GitHub repository
3. Use the configuration above
4. Deploy and monitor the logs for any issues 