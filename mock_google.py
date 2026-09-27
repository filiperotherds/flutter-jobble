import re

for folder in ['flutter-client', 'flutter-jobble']:
    path = f"C:/Projetos/jobble original/{folder}/lib/core/config/app_config.dart"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Change googleClientId to return a dummy string if missing
    old = "static const String googleClientId = String.fromEnvironment(\n      'GOOGLE_CLIENT_ID',\n    );"
    new = "static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: 'dummy');"
    
    content = content.replace(old, new)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
