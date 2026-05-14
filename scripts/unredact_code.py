import os
import re

# Use the file with a leading space as requested by the user's environment
env_path = ' .env'

# Keep this in sync with redact_code.py.
search_dirs = ['src', 'scripts', 'flutter_app/lib', 'flutter_app/android', 'include', 'data', 'web', 'flutter_app/web', 'sketch_apr15a']
extensions = ('.cpp', '.h', '.py', '.dart', '.json', '.xml', '.yaml', '.txt', '.ino', '.ini', '.md', '.html', '.js', '.css')

# Read mappings from " .env" and reverse KEY_PLACEHOLDER back to the real value.
mappings = []
if os.path.exists(env_path):
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                key = key.strip()
                val = val.strip()
                val = val.strip("'").strip('"')
                if val and key and len(val) > 3:
                    placeholder = f"{key}_PLACEHOLDER"
                    mappings.append((placeholder, val))

# Sort by placeholder length descending to mirror redaction ordering and avoid nested replacements.
mappings.sort(key=lambda x: len(x[0]), reverse=True)

print(f"Loaded {len(mappings)} placeholders.")

def unredact_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Could not read {file_path}: {e}")
        return

    original_content = content
    for placeholder, val in mappings:
        # Redaction maps both dotted and comma-separated IP forms to one placeholder.
        # Restore IPAddress(...) arguments to the comma-separated constructor form.
        if re.match(r'^\d{1,3}(\.\d{1,3}){3}$', val):
            comma_val = val.replace('.', ', ')
            content = re.sub(
                rf'(\bIPAddress(?:\s+\w+)?\s*\()\s*{re.escape(placeholder)}\s*(\))',
                rf'\g<1>{comma_val}\2',
                content,
            )

        content = content.replace(placeholder, val)

    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Unredacted: {file_path}")

for s_dir in search_dirs:
    if not os.path.exists(s_dir):
        continue
    for root, dirs, files in os.walk(s_dir):
        for file in files:
            if file.lower().endswith(extensions):
                unredact_file(os.path.join(root, file))

for file in os.listdir('.'):
    if file.lower().endswith(extensions) and os.path.isfile(file):
        unredact_file(file)

print("Unredaction complete.")
