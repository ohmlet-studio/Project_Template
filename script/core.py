"""
Core implementation of the asset sync system.
"""

import os
import json
import time
import subprocess
import threading
from pathlib import Path
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs

from config import *

# ============================================================================
# Configuration Management
# ============================================================================

def load_config():
    if not os.path.exists(USER_CONFIG_FILE):
        return DEFAULT_CONFIG.copy()
    
    with open(USER_CONFIG_FILE, 'r') as f:
        user_config = json.load(f)
    
    config = DEFAULT_CONFIG.copy()
    config.update(user_config)
    return config

def save_config(config):
    os.makedirs(SCRIPT_DIR, exist_ok=True)
    with open(USER_CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

def validate_config(config):
    if not config.get('repo_url'):
        return False, 'repo_url is required'
    if not config.get('ntu_name'):
        return False, 'ntu_name is required'
    if not config.get('git_username'):
        return False, 'git_username is required'
    if not config.get('git_email'):
        return False, 'git_email is required'
    return True, ''

# ============================================================================
# Git Operations
# ============================================================================

def init_git_repo():
    try:
        if not os.path.exists(os.path.join(REPO_ROOT, '.git')):
            subprocess.run(['git', 'init'], cwd=REPO_ROOT, check=True, capture_output=True)
        
        gitignore_path = os.path.join(REPO_ROOT, '.gitignore')
        with open(gitignore_path, 'w') as f:
            f.write('\n'.join(GIT_IGNORE_PATTERNS) + '\n')
        
        subprocess.run(['git', 'add', '.gitignore'], cwd=REPO_ROOT, check=True, capture_output=True)
        
        config = load_config()
        repo_url = config['repo_url']
        git_username = config['git_username']
        git_email = config['git_email']
        
        subprocess.run(['git', 'config', 'user.name', git_username], cwd=REPO_ROOT, check=True, capture_output=True)
        subprocess.run(['git', 'config', 'user.email', git_email], cwd=REPO_ROOT, check=True, capture_output=True)
        
        subprocess.run(['git', 'config', 'credential.helper', 'store'], cwd=REPO_ROOT, check=True, capture_output=True)
        
        try:
            subprocess.run(['git', 'remote', 'remove', 'origin'], cwd=REPO_ROOT, capture_output=True)
        except:
            pass
        
        subprocess.run(['git', 'remote', 'add', 'origin', repo_url], cwd=REPO_ROOT, check=True, capture_output=True)
        
        return True
    except Exception as e:
        print(f'Git initialization failed: {e}')
        return False

def test_git_authentication():
    print('\nTesting git authentication...')
    print('You will be prompted for your GitHub username and password/token.')
    print('Password: Use your GitHub password OR a Personal Access Token')
    print('(Token recommended: Settings > Developer settings > Personal access tokens > Tokens (classic))')
    print('')
    
    try:
        result = subprocess.run(['git', 'ls-remote', 'origin'], cwd=REPO_ROOT, capture_output=True, text=True)
        if result.returncode == 0:
            print('Authentication successful! Credentials saved.')
            return True
        else:
            print(f'Authentication failed: {result.stderr}')
            return False
    except Exception as e:
        print(f'Authentication test failed: {e}')
        return False

def format_commit_message(files, ntu_name):
    rel_files = []
    for f in files:
        rel_path = os.path.relpath(f, REPO_ROOT)
        rel_files.append(rel_path)
    
    if len(rel_files) == 0:
        return f'{ntu_name}: no files'
    
    if len(rel_files) == 1:
        return f'{ntu_name}: {rel_files[0]}'
    
    file_str = ', '.join(rel_files[:3])
    if len(rel_files) > 3:
        file_str += f' (+{len(rel_files) - 3} more)'
    
    return f'{ntu_name}: {file_str}'

def git_add_commit_push(files, ntu_name):
    if not files:
        return True
    
    try:
        for f in files:
            rel_path = os.path.relpath(f, REPO_ROOT)
            subprocess.run(['git', 'add', rel_path], cwd=REPO_ROOT, check=True, capture_output=True)
        
        commit_msg = format_commit_message(files, ntu_name)
        subprocess.run(['git', 'commit', '-m', commit_msg], cwd=REPO_ROOT, check=True, capture_output=True)
        
        subprocess.run(['git', 'push', 'origin', 'HEAD'], cwd=REPO_ROOT, check=True, capture_output=True)
        
        print(f'Committed and pushed: {commit_msg}')
        return True
    except subprocess.CalledProcessError as e:
        print(f'Git operation failed: {e}')
        return False

# ============================================================================
# File Watching (Desktop)
# ============================================================================

class FileWatcher:
    def __init__(self, ntu_name, batch_delay):
        self.ntu_name = ntu_name
        self.batch_delay = batch_delay
        self.pending_files = set()
        self.lock = threading.Lock()
        self.timer = None
    
    def on_file_change(self, filepath):
        with self.lock:
            self.pending_files.add(filepath)
            
            if self.timer:
                self.timer.cancel()
            
            self.timer = threading.Timer(self.batch_delay, self.process_batch)
            self.timer.start()
    
    def process_batch(self):
        with self.lock:
            if not self.pending_files:
                return
            
            files = list(self.pending_files)
            self.pending_files.clear()
        
        git_add_commit_push(files, self.ntu_name)

def start_file_watcher(ntu_name, batch_delay):
    try:
        from watchdog.observers import Observer
        from watchdog.events import FileSystemEventHandler
    except ImportError:
        print('Error: watchdog library not installed')
        print('Run: pip install watchdog')
        return
    
    watcher = FileWatcher(ntu_name, batch_delay)
    
    class AssetEventHandler(FileSystemEventHandler):
        def on_created(self, event):
            if not event.is_directory:
                watcher.on_file_change(event.src_path)
        
        def on_modified(self, event):
            if not event.is_directory:
                watcher.on_file_change(event.src_path)
    
    event_handler = AssetEventHandler()
    observer = Observer()
    observer.schedule(event_handler, ASSETS_DIR, recursive=WATCH_RECURSIVE)
    
    print(f'Watching {ASSETS_DIR} for changes...')
    print(f'Batch delay: {batch_delay} seconds')
    print(f'User: {ntu_name}')
    print('Press Ctrl+C to stop')
    
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

# ============================================================================
# Server Mode (iPadOS)
# ============================================================================

class UploadHandler(BaseHTTPRequestHandler):
    watcher = None
    
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html = '''
        <html>
        <head><title>Asset Upload</title></head>
        <body>
        <h1>Asset Upload Server</h1>
        <p>Server is running. Use iOS Shortcuts to upload files.</p>
        <p>Upload endpoint: POST /upload</p>
        </body>
        </html>
        '''
        self.wfile.write(html.encode())
    
    def do_POST(self):
        if self.path != '/upload':
            self.send_response(404)
            self.end_headers()
            return
        
        try:
            content_type = self.headers.get('Content-Type', '')
            if 'multipart/form-data' not in content_type:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid content type')
                return
            
            boundary = content_type.split('boundary=')[1].encode()
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            
            parts = body.split(b'--' + boundary)
            
            filename = None
            file_data = None
            
            for part in parts:
                if b'Content-Disposition' in part:
                    lines = part.split(b'\r\n')
                    for i, line in enumerate(lines):
                        if b'Content-Disposition' in line and b'filename=' in line:
                            filename_part = line.split(b'filename=')[1]
                            filename = filename_part.strip(b'"').decode('utf-8')
                            
                            for j in range(i + 1, len(lines)):
                                if lines[j] == b'':
                                    file_data = b'\r\n'.join(lines[j+1:])
                                    if file_data.endswith(b'\r\n'):
                                        file_data = file_data[:-2]
                                    break
                            break
            
            if not filename or file_data is None:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'No file provided')
                return
            
            filepath = os.path.join(ASSETS_DIR, filename)
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            
            with open(filepath, 'wb') as f:
                f.write(file_data)
            
            if UploadHandler.watcher:
                UploadHandler.watcher.on_file_change(filepath)
            
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f'File uploaded: {filename}'.encode())
            
            print(f'Received file: {filename}')
            
        except Exception as e:
            print(f'Upload error: {e}')
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())
    
    def log_message(self, format, *args):
        return

def start_upload_server(host, port, ntu_name, batch_delay):
    watcher = FileWatcher(ntu_name, batch_delay)
    UploadHandler.watcher = watcher
    
    server = HTTPServer((host, port), UploadHandler)
    
    print(f'Server running on http://{host}:{port}')
    print(f'Upload endpoint: http://{host}:{port}/upload')
    print(f'User: {ntu_name}')
    print(f'Batch delay: {batch_delay} seconds')
    print('Press Ctrl+C to stop')
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nShutting down server...')
        server.shutdown()

# ============================================================================
# Setup
# ============================================================================

def setup_environment():
    os.makedirs(PROJECT_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(BUILDS_DIR, exist_ok=True)
    os.makedirs(SCRIPT_DIR, exist_ok=True)
    
    return init_git_repo()

def check_dependencies():
    missing = []
    
    try:
        subprocess.run(['git', '--version'], capture_output=True, check=True)
    except:
        missing.append('git')
    
    try:
        import watchdog
    except ImportError:
        missing.append('watchdog (Python package)')
    
    return len(missing) == 0, missing
