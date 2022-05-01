#!/bin/sh
# This script serves as Docker entrypoint - the program
# that is run upon container start.

. ./expand-secrets.sh
# Run what we're instructed to, e.g. a binary, another script
# or just a shell command
exec "$@"
