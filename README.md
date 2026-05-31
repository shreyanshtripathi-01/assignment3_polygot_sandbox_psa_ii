# Polyglot Sandbox Automator

A secure, containerized code execution platform that lets you run Python and Node.js code in isolated containers via a simple REST API.

## What This Does

This project provides an API endpoint where you can send code snippets and get back the execution results. Think of it as a simplified version of what runs behind coding platforms like LeetCode or Replit - your code runs in its own temporary container with resource limits.

## Features

- **REST API**: Simple `POST /execute` endpoint
- **Multi-language**: Python 3.11 and Node.js 18 support
- **Secure runners**: Containers run as non-root users
- **Resource limits**: 256MB RAM and 0.5 CPU per execution
- **Redis caching**: Ready for rate limiting (can be extended)
- **One-command management**: Setup, build, test, clean, logs

## How To Run It

### First Time Setup
```bash
# Clone and enter
git clone https://github.com/shreyanshtripathi-01/assignment3_polygot_sandbox.git
cd assignment3_polygot_sandbox

# Check your system and pull base images
./scripts/manage.sh setup
```

### Build & Test
```bash
# Build all images
./scripts/manage.sh build

# Run quick tests
./scripts/manage.sh test
```

### Start The API
```bash
docker-compose up -d
# API runs at http://localhost:3000
```

### Try It Out

Send Python code:
```bash
curl -X POST http://localhost:3000/execute \
  -H "Content-Type: application/json" \
  -d '{"code": "for i in range(5): print(i)", "language": "python"}'
```

Send Node.js code:
```bash
curl -X POST http://localhost:3000/execute \
  -H "Content-Type: application/json" \
  -d '{"code": "console.log(\"Hello from Node.js!\")", "language": "nodejs"}'
```

## Management Script

The `manage.sh` script handles everything:

| Command | What It Does |
|---------|-------------|
| `setup` | Checks Docker/Git, creates temp directory |
| `build` | Builds Docker images tagged with git commit |
| `test` | Runs Hello World tests in both languages |
| `clean` | Removes containers, images, and temp files |
| `logs` | Shows live logs with errors highlighted in red |

## Project Layout

```
src/                 # TypeScript API code
containers/
├── api/            # API Dockerfile
├── python/         # Python runner (secure sandbox)
└── nodejs/         # Node.js runner (secure sandbox)
scripts/manage.sh   # All-in-one control script
docker-compose.yml  # Redis + API setup
```

## CI/CD Pipeline

This project includes a full Jenkins pipeline that:
- Runs SonarQube quality scans
- Builds and tags Docker images
- Deploys to AWS with Elastic IP

See `Jenkinsfile` for the pipeline definition.

## Resources

- **Postman Collection**: [Download Collection](https://raw.githubusercontent.com/shreyanshtripathi-01/assignment3_polygot_sandbox/main/postman-collection.json)
- **Docker Hub Image**: [polyglot-sandbox](https://hub.docker.com/r/tripathishreyansh-01/polyglot-sandbox)
- **GitHub Repository**: [assignment3_polygot_sandbox](https://github.com/shreyanshtripathi-01/assignment3_polygot_sandbox)

## License

MIT - Feel free to fork and modify!
