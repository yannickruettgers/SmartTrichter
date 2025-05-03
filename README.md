# SmartTrichter

## CI/CD Setup

This repository uses a modular GitHub Actions pipeline to deploy `infrastructure`, `backend`, and `frontend` components based on changes in the monorepo.

### Workflow Structure

- **Main workflow**: `.github/workflows/trigger-deployments.yml`
  - Detects changes via `git diff`
  - Determines the target environment based on the branch:
    - `main` → `prod`
    - all others → `dev`
  - Triggers reusable workflows conditionally
- **Reusable workflows**:
  - `infrastructure.yml` – Terraform-based deployment
  - `backend.yml` – Serverless deployment
  - `frontend.yml` – S3 static site deployment

### GitHub Environments

- Two environments are defined: `dev` and `prod`
- Each environment includes:
  - Scoped secrets
  - An environment variable `ENVIRONMENT` set to `dev` or `prod`
  - Optional protection rules (e.g., required reviewers for `prod`)

### Deployment Logic

1. The `trigger-deployments.yml` workflow detects changes by comparing the current branch to `main`.
2. Affected projects (`frontend`, `backend`, `infrastructure`) are identified based on file paths.
3. If infrastructure is affected, it is deployed first.
4. Frontend and backend are deployed in parallel if affected.
5. Each job declares its GitHub Environment to enable environment-specific rules and secrets.

### File Structure

<pre><code>
.github/workflows/ 
├── trigger-deployments.yml # Main orchestration workflow 
├── infrastructure.yml # Reusable Terraform deployment 
├── backend.yml # Reusable Serverless deployment 
└── frontend.yml # Reusable S3 deployment 
</code></pre>

### Requirements

- GitHub Environments named `dev` and `prod`
- Each environment must define:
  - A variable `ENVIRONMENT` with value `dev` or `prod`
  - Any required secrets (e.g., AWS credentials)
- All reusable workflows use `workflow_call` and access `inputs.environment` or `${{ vars.ENVIRONMENT }}`

