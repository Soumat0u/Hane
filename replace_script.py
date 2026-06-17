import os
import re

def fix_colors(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Scaffold
    content = re.sub(r'const\s+Color\(0xFFF8FAFC\)', 'context.colors.scaffold', content)
    content = content.replace('Color(0xFFF8FAFC)', 'context.colors.scaffold')
    
    # Surface
    content = re.sub(r'const\s+Color\(0xFF1A2436\)', 'context.colors.surface', content)
    content = content.replace('Color(0xFF1A2436)', 'context.colors.surface')
    content = re.sub(r'const\s+Color\(0xFFFFFFFF\)', 'context.colors.surface', content)
    content = content.replace('Color(0xFFFFFFFF)', 'context.colors.surface')
    content = content.replace('Colors.white', 'context.colors.surface')
    
    # Texts
    content = re.sub(r'const\s+Color\(0xFF1E293B\)', 'context.colors.textPrimary', content)
    content = content.replace('Color(0xFF1E293B)', 'context.colors.textPrimary')
    content = re.sub(r'const\s+Color\(0xFF64748B\)', 'context.colors.textSecondary', content)
    content = content.replace('Color(0xFF64748B)', 'context.colors.textSecondary')
    content = re.sub(r'const\s+Color\(0xFF94A3B8\)', 'context.colors.textSecondary', content)
    content = content.replace('Color(0xFF94A3B8)', 'context.colors.textSecondary')
    content = re.sub(r'const\s+Color\(0xFF475569\)', 'context.colors.textSecondary', content)
    content = content.replace('Color(0xFF475569)', 'context.colors.textSecondary')
    
    # Brands and Accents
    content = re.sub(r'const\s+Color\(0xFF032B5E\)', 'context.colors.brand', content)
    content = content.replace('Color(0xFF032B5E)', 'context.colors.brand')
    content = re.sub(r'const\s+Color\(0xFF3B82F6\)', 'context.colors.accent', content)
    content = content.replace('Color(0xFF3B82F6)', 'context.colors.accent')
    
    # Borders and variants
    content = re.sub(r'const\s+Color\(0xFFE2E8F0\)', 'context.colors.border', content)
    content = content.replace('Color(0xFFE2E8F0)', 'context.colors.border')
    content = re.sub(r'const\s+Color\(0xFFF1F5F9\)', 'context.colors.surfaceVariant', content)
    content = content.replace('Color(0xFFF1F5F9)', 'context.colors.surfaceVariant')

    # Remove invalid consts left over from regex replacements
    content = re.sub(r'const\s+TextStyle\(\s*color:\s*context\.colors', r'TextStyle(color: context.colors', content)
    content = re.sub(r'const\s+Icon\(\s*([^,]+),\s*color:\s*context\.colors', r'Icon(\1, color: context.colors', content)
    content = re.sub(r'const\s+BoxDecoration\(\s*color:\s*context\.colors', r'BoxDecoration(color: context.colors', content)

    # Rename Anasayfa -> Finansal Durum
    content = content.replace("'Anasayfa'", "'Finansal Durum'")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(r'c:\Users\PC\Desktop\Projeler\hano\lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_colors(os.path.join(root, file))

print('Done')
