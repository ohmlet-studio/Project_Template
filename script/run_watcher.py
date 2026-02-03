#!/usr/bin/env python3
"""
File watcher for desktop NTU users.
Monitors project/assets directory and auto-commits changes.
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from core import *
from config import *

def main():
    config = load_config()
    
    is_valid, error = validate_config(config)
    if not is_valid:
        print(f'Error: {error}')
        print('Run setup.py first to configure the system.')
        sys.exit(1)
    
    all_deps, missing = check_dependencies()
    if not all_deps:
        print('Missing dependencies:')
        for dep in missing:
            print(f'  - {dep}')
        sys.exit(1)
    
    ntu_name = config['ntu_name']
    batch_delay = config['batch_delay_seconds']
    
    start_file_watcher(ntu_name, batch_delay)

if __name__ == '__main__':
    main()
