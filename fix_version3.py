import re

for folder in ['flutter-client', 'flutter-jobble']:
    path = f"C:/Projetos/jobble original/{folder}/pubspec.yaml"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = re.sub(r'version: 1\.0\.0\+\d+', 'version: 1.0.0+102', content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
