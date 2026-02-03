# Godot game template

Template to allow non-technical users to directly upload their assets inside the repo.

## Structure

```
project/
  assets/          # Monitored + Sync
builds/            # Build project (HTML etc) / ignored by git
script/            # Sync scripts (ignored by git)
  config.py        # Global variables
  functions.py     # Function declarations
  core.py          # Core implementation
  setup.py         # Initial setup (TU only)
  run_watcher.py   # Desktop file watcher (NTU)
  run_server.py    # iPadOS upload server (NTU)
  requirements.txt # Python dependencies
  setup_venv.sh    # Virtual environment setup (Unix)
  setup_venv.bat   # Virtual environment setup (Windows)
```

## Prerequisites

- Python 3.7+
- Git
- GitHub account for us and artists.

## Initial Setup

### For Ruben et compagnie

1. Clone this repo for a game
2. **Artists on computer**:
  - Add each account to repo (comme d'hab)
3. **Artists on iPad / iPhone**
   - Create a bot account (one for Rock Bottom)
   - Add bot account as collaborator with write access

### 3. Setup Virtual Environment

Linux/Mac:
```bash
cd script
bash setup_venv.sh
```

Windows:
```bash
cd script
setup_venv.bat
```

### 4. Run Setup Script

Linux/Mac:
```bash
source venv/bin/activate
python setup.py
```

Windows:
```bash
venv\Scripts\activate.bat
python setup.py
```

Access tokens are preferred (securityyyyy).

Configuration is saved to `script/user_config.json` .

## Usage

### Desktop

1. Activate virtual environment:

Linux/Mac:
```bash
cd script
source venv/bin/activate
```

Windows (beurk):
```bash
cd script
venv\Scripts\activate.bat
```

2. Run file watcher:
```bash
python run_watcher.py
```

3. Add/modify files in `project/assets/`

### iPad / iPhone 

#### Server Setup 

1. Run setup with bot account 
2. Activate virtual environment
3. Run upload server:
```bash
python run_server.py
```
4. Share IP/port

#### iOS Shortcuts Configuration

Download the shortcut:
![Link to shortcut on proton drive](https://drive.proton.me/urls/RK1AM9BV6G#U6A4tla0upeX)

## Commit Format

Commits follow the format:
```
<Display Name>: <files>
```

Examples:
- `Spoul: perso.png` (desktop)
- `Assets Bot: textures/tableau.png, textures/pierre.png (+2 more)` iPad/iPhone

## Configuration Parameters

- `repo_url`: GitHub repository
- `git_username`: GitHub username 
- `git_email`: GitHub email 
- `ntu_name`: Display name used in commit 
- `batch_delay_seconds`: Time to wait before committing batched changes
- `max_file_size_mb`: Maximum file size allowed
- `server_port`: HTTP server port 
- `server_host`: Server host address (not really needed, just find your own)

## Troubleshooting

### Dependencies Missing
Run virtual environment setup script again.

### Permission Denied
Contact Ruben to verify you've been added as a collaborator with Write access.

### iPadOS Upload Failed
Verify server is running and IP/port are correct in Shortcut.

### Credentials Not Saving
Check if `~/.git-credentials` file exists and has correct permissions.
