import re

for folder in ['flutter-client', 'flutter-jobble']:
    path = f"C:/Projetos/jobble original/{folder}/lib/features/auth/presentation/widgets/google_sign_in_button.dart"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # replace OutlinedButton.icon to the end of the file
    old = "    return OutlinedButton.icon("
    new_content = """    return AppSecondaryButton(
      onPressed: _busy ? null : _startNativeFlow,
      icon: SvgPicture.asset(AppAssets.googleIcon, width: 20, height: 20),
      label: 'Entrar com o Google',
      isLoading: _busy,
    );
  }
}
"""
    
    # We need to slice the file at the return statement and append the new content
    index = content.find(old)
    if index != -1:
        content = content[:index] + new_content
    
    # Also add the import for AppSecondaryButton if not there
    if "app_buttons.dart" not in content:
        import_stmt = "import 'package:flutter_tcc/core/widgets/app_buttons.dart';\n"
        if folder == 'flutter-client':
            import_stmt = import_stmt.replace('flutter_tcc', 'jobble_client')
        
        # add import after material
        content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_stmt}")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
