"""
Global configuration variables for the asset sync system.
All paths are relative to the repository root.
"""

import os

# Repository structure
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
PROJECT_DIR = os.path.join(REPO_ROOT, 'project')
ASSETS_DIR = os.path.join(PROJECT_DIR, 'assets')
BUILDS_DIR = os.path.join(REPO_ROOT, 'builds')
SCRIPT_DIR = os.path.join(REPO_ROOT, 'script')
VENV_DIR = os.path.join(SCRIPT_DIR, 'venv')

# User configuration file (not tracked in git)
USER_CONFIG_FILE = os.path.join(SCRIPT_DIR, 'user_config.json')

# Default configuration values
DEFAULT_CONFIG = {
    'repo_url': '',
    'ntu_name': 'NTU',
    'git_username': '',
    'git_email': '',
    'batch_delay_seconds': 60,
    'max_file_size_mb': 100,
    'server_port': 8080,
    'server_host': '0.0.0.0'
}

# Git configuration
GIT_IGNORE_PATTERNS = [
    'script/',
    'builds/',
    'script/venv/',
    'script/__pycache__/',
    'script/*.pyc',
    'script/user_config.json',
    '.DS_Store'
]

# File watcher settings
WATCH_RECURSIVE = True
DEBOUNCE_SECONDS = 2

# Server settings
UPLOAD_ALLOWED_EXTENSIONS = set()  # Empty set means all extensions allowed
