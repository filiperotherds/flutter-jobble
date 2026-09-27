with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

import re
content = re.sub(r'version: 1\.0\.0\+\d+', 'version: 1.0.0+99', content)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
