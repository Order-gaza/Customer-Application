import os
import re

lib_dir = r"D:\_backend\final\order_app\lib"

replacements = {
    'AppColors.scaffoldDark': 'context.cx.scaffold',
    'AppColors.darkSurface': 'context.cx.surface',
    'AppColors.cardDark': 'context.cx.card',
    'AppColors.charcoalBlack': 'context.cx.appBar',
    'AppColors.textSecondary': 'context.cx.textSecondary',
    'AppColors.divider': 'context.cx.divider',
    'AppColors.shimmerBase': 'context.cx.shimmerBase',
    'AppColors.shimmerHighlight': 'context.cx.shimmerHighlight',
}

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if not filename.endswith('.dart'): continue
        # Ignore already patched files and AppColors/Theme files
        if filename in ('theme_colors.dart', 'app_colors.dart', 'main.dart', 'settings_view.dart', 'main_shell.dart'): continue
        
        filepath = os.path.join(root, filename)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        
        # Replace colors
        for key, val in replacements.items():
            content = content.replace(key, val)
            
        # We need to manually fix Colors.white in some places if needed, but AppColors is safer.
        
        if content != original_content:
            # Fix const issues with regex
            # e.g. const TextStyle(color: context.cx.textSecondary) -> TextStyle(...)
            # Because cx requires context which is not const
            content = re.sub(r'const\s+(TextStyle\([^)]*context\.cx[^)]*\))', r'\1', content)
            content = re.sub(r'const\s+(Icon\([^)]*context\.cx[^)]*\))', r'\1', content)
            content = re.sub(r'const\s+(BorderSide\([^)]*context\.cx[^)]*\))', r'\1', content)
            content = re.sub(r'const\s+(BoxDecoration\([^)]*context\.cx[^)]*\))', r'\1', content)
            # Remove const where there's a nested const, like const Center(child: CircularProgressIndicator(color: context.cx...)) -> Center(child: ...)
            content = re.sub(r'const\s+(Center\([^)]*context\.cx[^)]*\))', r'\1', content)
            content = re.sub(r'const\s+(Divider\([^)]*context\.cx[^)]*\))', r'\1', content)
            
            # Inject import
            if 'ThemeColorsExtension' not in content and 'app/theme/theme_colors.dart' not in content:
                # Basic package import
                pkg_import = "import 'package:order_app/app/theme/theme_colors.dart';"
                if pkg_import not in content:
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if line.startswith('import '):
                            lines.insert(i + 1, pkg_import)
                            break
                    content = '\n'.join(lines)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
                
print("Done!")
