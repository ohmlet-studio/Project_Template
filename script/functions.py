"""
Public function declarations for the asset sync system.
Contains all externally accessible functions with their signatures and purposes.
"""

# Configuration Management
def load_config():
    """
    Loads user configuration from user_config.json.
    Returns: dict with configuration values, using defaults for missing keys.
    """
    pass

def save_config(config):
    """
    Saves user configuration to user_config.json.
    Args: config (dict) - configuration dictionary to save.
    """
    pass

def validate_config(config):
    """
    Validates required configuration fields are present and valid.
    Args: config (dict) - configuration to validate.
    Returns: tuple (bool, str) - (is_valid, error_message).
    """
    pass

# Git Operations
def init_git_repo():
    """
    Initializes git repository and creates .gitignore.
    Returns: bool - success status.
    """
    pass

def test_git_authentication():
    """
    Tests git authentication by attempting to connect to remote repository.
    Prompts user for credentials on first run.
    Returns: bool - success status.
    """
    pass

def git_add_commit_push(files, ntu_name):
    """
    Adds files to git, commits with formatted message, and pushes to remote.
    Args: files (list) - list of file paths relative to repo root.
          ntu_name (str) - name of the NTU user.
    Returns: bool - success status.
    """
    pass

def format_commit_message(files, ntu_name):
    """
    Formats commit message as '<NTU name>: <modification or addition of files>'.
    Args: files (list) - list of file paths.
          ntu_name (str) - name of the NTU user.
    Returns: str - formatted commit message.
    """
    pass

# File Watching (Desktop)
def start_file_watcher(ntu_name, batch_delay):
    """
    Starts file system watcher for project/assets directory.
    Args: ntu_name (str) - name of the NTU user.
          batch_delay (int) - seconds to wait before batching commits.
    """
    pass

# Server Mode (iPadOS)
def start_upload_server(host, port, ntu_name, batch_delay):
    """
    Starts HTTP server to receive file uploads from iPadOS devices.
    Args: host (str) - server host address.
          port (int) - server port.
          ntu_name (str) - name of the NTU user.
          batch_delay (int) - seconds to wait before batching commits.
    """
    pass

# Setup
def setup_environment():
    """
    Creates necessary directories and initializes git repository.
    Returns: bool - success status.
    """
    pass

def check_dependencies():
    """
    Checks if required system dependencies are installed.
    Returns: tuple (bool, list) - (all_installed, missing_dependencies).
    """
    pass
