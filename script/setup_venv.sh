#!/bin/bash
# Virtual environment setup script
# Run this once before using the asset sync system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

echo "Setting up virtual environment..."

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "Virtual environment created."
else
    echo "Virtual environment already exists."
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

echo "Installing dependencies..."
pip install --upgrade pip
pip install -r "$SCRIPT_DIR/requirements.txt"

echo ""
echo "Setup complete."
echo ""
echo "To activate the virtual environment manually:"
echo "  source $VENV_DIR/bin/activate"
echo ""
echo "To run setup (TU only):"
echo "  source $VENV_DIR/bin/activate && python setup.py"
echo ""
echo "To run file watcher (NTU Desktop):"
echo "  source $VENV_DIR/bin/activate && python run_watcher.py"
echo ""
echo "To run upload server (NTU iPadOS):"
echo "  source $VENV_DIR/bin/activate && python run_server.py"
