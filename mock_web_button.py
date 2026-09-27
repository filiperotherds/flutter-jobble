import re

for folder in ['flutter-client', 'flutter-jobble']:
    path = f"C:/Projetos/jobble original/{folder}/lib/features/auth/presentation/widgets/google_button_web.dart"
    with open(path, 'w', encoding='utf-8') as f:
        f.write("import 'package:flutter/material.dart';\nWidget? renderGoogleButton() => null;")
