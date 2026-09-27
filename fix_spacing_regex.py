import re

with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Use regex to find the place before "Atalhos da sua conta"
# Specifically, we want to find the Padding block that contains the text 'Atalhos da sua conta'
# and insert a SizedBox before it.
pattern = r"(\s*// Atalhos.*?Padding\(\s*padding: EdgeInsets\.symmetric\(horizontal: AppSpacing\.md\),\s*child: Text\(\s*'Atalhos da sua conta')"

# Let's see if we can find it
match = re.search(pattern, content, flags=re.DOTALL)
if match:
    # Insert SizedBox(height: 40) right before the comment/Padding
    replacement = r"\n                const SizedBox(height: 48),\n\1"
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Pattern not found")
