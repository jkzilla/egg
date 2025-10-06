# CircleCI Docker Hub Setup

## Add Docker Hub Context

1. Go to: https://app.circleci.com/settings/organization/github/jkzilla/contexts
2. Click **Create Context**
3. Name it: `docker-hub-creds`
4. Click **Add Environment Variable** twice to add:

### Environment Variables

| Name | Value |
|------|-------|
| `DOCKER_USERNAME` | `zealousidealowl` |
| `DOCKER_PASSWORD` | `<your-docker-hub-personal-access-token>` |

## How It Works

The CircleCI workflow will:
1. Build the Docker image
2. Tag it as `zealousidealowl/haileys-garden:latest` and `zealousidealowl/haileys-garden:<commit-sha>`
3. Test the image
4. Push to Docker Hub (only on main/master branch)

## Workflow

```
Security Scan → Backend Build → Frontend Build → Integration Test → Docker Build & Push
```

The docker-build job only runs on main/master/develop branches and requires the `docker-hub-creds` context.
