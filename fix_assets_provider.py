with open('lib/core/constants/app_assets.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("intro_illustration.jpg", "intro_illustration.png")

with open('lib/core/constants/app_assets.dart', 'w', encoding='utf-8') as f:
    f.write(content)
