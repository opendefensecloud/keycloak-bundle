# Contributing

Thanks for your interest in contributing to the Keycloak Solution project.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Run `./scripts/init-dirs.sh` to create directory structure
4. Create a feature branch

## Development Setup

### Prerequisites

- Kubernetes cluster (1.28+)
- kubectl configured
- Bash shell

### Deploy Development Instance

```bash
./scripts/deploy-instance.sh dev
./scripts/dev-portforward.sh dev
# Open http://localhost:8080
```

### View Logs

```bash
./scripts/dev-logs.sh keycloak dev
./scripts/dev-logs.sh postgres dev
```

### Cleanup

```bash
./scripts/cleanup.sh dev
```

## Code Style

- YAML: 2-space indentation
- Shell scripts: Use `set -e`, quote variables
- Markdown: Keep it concise

## Submitting Changes

1. Create a feature branch from `main`
2. Make your changes
3. Test with `./scripts/deploy-all.sh`
4. Commit with clear message
5. Push and open a Pull Request

### Commit Messages

Format: `<type>: <description>`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance

Example: `feat: add KeycloakRealm CRD`

## Pull Request Process

1. Ensure tests pass
2. Update documentation if needed
3. Request review
4. Squash commits before merge

## Reporting Issues

Open an issue with:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Kubernetes version

## Architecture Decisions

Major changes should be documented as ADRs in `docs/adrs/`.
Discuss in an issue first before implementing.

## License

By contributing, you agree that your contributions will be licensed under Apache 2.0.
