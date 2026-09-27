with open('lib/features/requests/presentation/widgets/service_stepper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("colors.primary", "const Color(0xFF1C574A)")

with open('lib/features/requests/presentation/widgets/service_stepper.dart', 'w', encoding='utf-8') as f:
    f.write(content)
