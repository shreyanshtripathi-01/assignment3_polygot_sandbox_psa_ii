#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMP_DIR="/tmp/polyglot-sandbox"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

command=${1:-}

setup() {
    echo -e "${GREEN}Setting up environment...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker not found. Please install Docker.${NC}"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Git not found. Please install Git.${NC}"
        exit 1
    fi
    
    mkdir -p "$TEMP_DIR"
    
    echo -e "${GREEN}Pulling base images...${NC}"
    docker pull node:18-alpine
    docker pull python:3.11-alpine
    docker pull redis:7-alpine
    
    echo -e "${GREEN}Setup complete!${NC}"
}

build() {
    echo -e "${GREEN}Building images...${NC}"
    
    COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
    
    docker build -t sandbox-api:$COMMIT_SHA -t sandbox-api:latest -f "$PROJECT_DIR/containers/api/Dockerfile" "$PROJECT_DIR/src"
    docker build -t sandbox-python-runner:$COMMIT_SHA -t sandbox-python-runner:latest -f "$PROJECT_DIR/containers/python/Dockerfile" "$PROJECT_DIR/containers/python"
    docker build -t sandbox-nodejs-runner:$COMMIT_SHA -t sandbox-nodejs-runner:latest -f "$PROJECT_DIR/containers/nodejs/Dockerfile" "$PROJECT_DIR/containers/nodejs"
    
    echo -e "${GREEN}Build complete! Images tagged with commit $COMMIT_SHA${NC}"
}

test() {
    echo -e "${GREEN}Running integration tests...${NC}"
    
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d redis
    
    sleep 2
    
    echo -e "${YELLOW}Testing Python runner...${NC}"
    docker run --rm --memory=256m --cpus=0.5 -v "$PROJECT_DIR/containers/python:/code" -w /code sandbox-python-runner:latest sh -c "echo 'print(\"Hello from Python!\")' > code.py && python code.py"
    
    echo -e "${YELLOW}Testing Node.js runner...${NC}"
    docker run --rm --memory=256m --cpus=0.5 -v "$PROJECT_DIR/containers/nodejs:/code" -w /code sandbox-nodejs-runner:latest sh -c "echo 'console.log(\"Hello from Node.js!\")' > code.js && node code.js"
    
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" down
    
    echo -e "${GREEN}All tests passed!${NC}"
}

clean() {
    echo -e "${GREEN}Cleaning up...${NC}"
    
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" down -v 2>/dev/null || true
    
    docker rmi sandbox-api:latest sandbox-python-runner:latest sandbox-nodejs-runner:latest 2>/dev/null || true
    docker image prune -f 2>/dev/null || true
    
    rm -rf "$TEMP_DIR" 2>/dev/null || true
    
    echo -e "${GREEN}Cleanup complete!${NC}"
}

logs() {
    echo -e "${GREEN}Tailing logs (ERROR|CRITICAL in red)...${NC}"
    echo "Press Ctrl+C to stop"
    
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" logs -f --tail=100 2>/dev/null | while IFS= read -r line; do
        if echo "$line" | grep -qiE 'ERROR|CRITICAL'; then
            echo -e "${RED}$line${NC}"
        else
            echo "$line"
        fi
    done
}

case $command in
    setup) setup ;;
    build) build ;;
    test) test ;;
    clean) clean ;;
    logs) logs ;;
    *) echo "Usage: $0 {setup|build|test|clean|logs}" ;;
esac
