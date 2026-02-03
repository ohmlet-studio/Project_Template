#!/usr/bin/env python3
"""
Setup script for Technical Users (TU).
Configures the asset sync system with repository URL and GitHub token.
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from core import *
from config import *

def main():
    print('=== Asset Sync Setup ===\n')
    
    config = load_config()
    
    print('Enter configuration values (press Enter to keep current value):\n')
    
    repo_url = input(f'Repository URL (HTTPS format) [{config.get("repo_url", "")}]: ').strip()
    if repo_url:
        config['repo_url'] = repo_url
    
    git_username = input(f'GitHub Username [{config.get("git_username", "")}]: ').strip()
    if git_username:
        config['git_username'] = git_username
    
    git_email = input(f'GitHub Email [{config.get("git_email", "")}]: ').strip()
    if git_email:
        config['git_email'] = git_email
    
    ntu_name = input(f'Display Name (for commits) [{config.get("ntu_name", "NTU")}]: ').strip()
    if ntu_name:
        config['ntu_name'] = ntu_name
    
    batch_delay = input(f'Batch Delay (seconds) [{config.get("batch_delay_seconds", 60)}]: ').strip()
    if batch_delay:
        try:
            config['batch_delay_seconds'] = int(batch_delay)
        except ValueError:
            print('Invalid number, keeping current value')
    
    max_size = input(f'Max File Size (MB) [{config.get("max_file_size_mb", 100)}]: ').strip()
    if max_size:
        try:
            config['max_file_size_mb'] = int(max_size)
        except ValueError:
            print('Invalid number, keeping current value')
    
    server_port = input(f'Server Port (for iPadOS) [{config.get("server_port", 8080)}]: ').strip()
    if server_port:
        try:
            config['server_port'] = int(server_port)
        except ValueError:
            print('Invalid number, keeping current value')
    
    is_valid, error = validate_config(config)
    if not is_valid:
        print(f'\nError: {error}')
        sys.exit(1)
    
    save_config(config)
    print('\nConfiguration saved.')
    
    print('\nSetting up environment...')
    if not setup_environment():
        print('Environment setup failed.')
        sys.exit(1)
    
    print('Environment setup complete.')
    
    if not test_git_authentication():
        print('\nWarning: Git authentication failed.')
        print('You can retry authentication later by running setup.py again.')
    
    print('\nSetup complete. Configuration saved to user_config.json')
    print('\nNext steps:')
    print('  - NTU Desktop: Run "python run_watcher.py"')
    print('  - NTU iPadOS: Run "python run_server.py" and configure iOS Shortcuts')

if __name__ == '__main__':
    main()
