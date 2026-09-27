with open('lib/features/home/presentation/pages/provider_shell_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_idx = content.find("              const SizedBox(height: AppSpacing.lg),")
if start_idx != -1:
    print(content[start_idx:start_idx+500])
