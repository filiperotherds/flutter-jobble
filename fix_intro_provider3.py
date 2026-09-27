with open('lib/features/onboard/presentation/pages/intro_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("label: 'J\u00e3\u00a1 tenho uma conta',\n                      onPressed: () => Navigator.push(\n                        context,\n                        MaterialPageRoute(builder: (_) => const LoginPage()),\n                      ),", "REPLACE_ME")
content = content.replace("label: 'Criar nova conta',\n                      onPressed: () => Navigator.push(\n                        context,\n                        MaterialPageRoute(builder: (_) => const SignupPage()),\n                      ),", "label: 'J\u00e1 tenho uma conta',\n                      onPressed: () => Navigator.push(\n                        context,\n                        MaterialPageRoute(builder: (_) => const LoginPage()),\n                      ),")
content = content.replace("REPLACE_ME", "label: 'Criar nova conta',\n                      onPressed: () => Navigator.push(\n                        context,\n                        MaterialPageRoute(builder: (_) => const SignupPage()),\n                      ),")


with open('lib/features/onboard/presentation/pages/intro_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
