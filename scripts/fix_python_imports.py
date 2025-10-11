#!/usr/bin/env python3
"""Fix Python protobuf imports to use relative imports for proper package structure."""

import os
import sys
import re

def fix_imports(directory):
    """Convert absolute imports to relative imports in generated Python files."""
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a directory")
        return False

    for filename in os.listdir(directory):
        if filename.endswith('_pb2.py'):
            filepath = os.path.join(directory, filename)

            with open(filepath, 'r') as f:
                content = f.read()

            # Replace absolute imports with relative imports
            # Pattern: import xxx_pb2 as xxx__pb2
            # Replace with: from . import xxx_pb2 as xxx__pb2
            pattern = r'^import (\w+_pb2) as'
            replacement = r'from . import \1 as'

            new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

            if new_content != content:
                with open(filepath, 'w') as f:
                    f.write(new_content)
                print(f"Fixed imports in {filename}")

    return True

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: fix_python_imports.py <directory>")
        sys.exit(1)

    success = fix_imports(sys.argv[1])
    sys.exit(0 if success else 1)