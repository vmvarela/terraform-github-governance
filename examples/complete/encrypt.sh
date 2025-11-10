#!/bin/bash
# Wrapper script to encrypt secrets for GitHub Actions
# Usage: ./encrypt.sh "your-secret-value"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    echo "Installing PyNaCl..."
    pip install PyNaCl --quiet
else
    source "$VENV_DIR/bin/activate"
fi

# Run the encryption script
python3 "$SCRIPT_DIR/encrypt_secret.py" "$@"

deactivate
