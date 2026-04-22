import os
import re

# File paths
env_path = ' .env'
src_dir = 'src'

# Read .env to get mappings (Key to Value)
mappings = {}
if os.path.exists(env_path):
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                key = key.strip()
                val = val.strip()
                if val and key:
                    mappings[key] = val

# Process files in src/
for root, dirs, files in os.walk(src_dir):
    for file in files:
        if file.endswith(('.cpp', '.h')):
            file_path = os.path.join(root, file)
            with open(file_path, 'r') as f:
                content = f.read()
            
            original_content = content
            for key, val in mappings.items():
                # Replace exact macro names with values
                # If key looks like an IP target and is inside IPAddress(), handle variation
                if key.startswith('PING_TARGET_'):
                    comma_val = val.replace('.', ', ')
                    content = content.replace(f'IPAddress({key})', f'IPAddress({comma_val})')
                
                # Replace macro names in strings/code
                # We target known placeholders or the macro names themselves
                content = content.replace(key, val)

            if content != original_content:
                with open(file_path, 'w') as f:
                    f.write(content)
                print(f"Unredacted: {file_path}")
