with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import_str = "import 'package:flutter_tcc/features/home/presentation/pages/provider_tips_page.dart';"
if import_str not in content:
    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_str}")

# Find the empty onPressed inside the banner
old_onpressed = """                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom("""

new_onpressed = """                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ProviderTipsPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom("""

content = content.replace(old_onpressed, new_onpressed)

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
