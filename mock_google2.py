import re

for folder in ['flutter-client', 'flutter-jobble']:
    path = f"C:/Projetos/jobble original/{folder}/lib/core/config/app_config.dart"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = re.sub(r"static const String googleClientId = .*?;", "static const String googleClientId = 'dummy_id_for_ui';", content, flags=re.DOTALL)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
