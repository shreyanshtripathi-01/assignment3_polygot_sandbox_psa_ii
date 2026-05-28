FROM python:3.11-alpine

# Security: create non-root user for sandbox
RUN addgroup -g 1001 -S sandbox && \
    adduser -u 1001 -S sandbox -G sandbox -s /bin/sh

USER sandbox

WORKDIR /code
CMD ["python", "code.py"]
