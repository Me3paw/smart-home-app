import os
import re

# Use the file with a leading space as requested by the user's environment
env_path = ' .env'

# Base directories to search for code and config files
search_dirs = ['src', 'scripts', 'flutter_app/lib', 'flutter_app/android', 'include', 'data', 'web', 'flutter_app/web']

# Suffixes of files to redact
extensions = ('.cpp', '.h', '.py', '.dart', '.json', '.xml', '.yaml', '.txt', '.ino', '.ini', '.md', '.html', '.js', '.css')

# Load mappings from " .env"
mappings = []
if os.path.exists(env_path):
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                key = key.strip()
                val = val.strip()
                # Clean value of potential quotes
                val = val.strip("'").strip('"')
                if val and key and len(val) > 3: # Avoid redacting extremely short strings
                    placeholder = f"{key}_PLACEHOLDER"
                    mappings.append((val, placeholder))
                    
                    # IP specific variation for C++ IPAddress(192, 168, 1, 1)
                    if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', val):
                        comma_val = val.replace('.', ', ')
                        mappings.append((comma_val, placeholder))

# Sort by length descending to handle nested matches (e.g. URL vs Domain)
mappings.sort(key=lambda x: len(x[0]), reverse=True)

print(f"Loaded {len(mappings)} sensitive patterns.")

def redact_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Could not read {file_path}: {e}")
        return

    original_content = content
    for val, placeholder in mappings:
        # 1. Simple replacement (handles URLs, MACs, etc.)
        content = content.replace(val, placeholder)
        
        # 2. Case-insensitive replacement for things like emails if needed
        # (Using simple replace for now as placeholders are usually specific)

    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Redacted: {file_path}")

# Run redaction
for s_dir in search_dirs:
    if not os.path.exists(s_dir):
        continue
    for root, dirs, files in os.walk(s_dir):
        for file in files:
            if file.endswith(extensions):
                redact_file(os.path.join(root, file))

# Special case: Also redact root files like platformio.ini
for file in os.listdir('.'):
    if file.endswith(extensions) and os.path.isfile(file):
        redact_file(file)

print("Redaction complete.")
