path = r'c:\Users\PC\Desktop\Projeler\hano\lib\views\widgets\bottom_navbar.dart'
with open(path, 'r', encoding='utf-8') as f: content = f.read()
content = content.replace('_buildNavItem(0, Icons.home_rounded, \'Anasayfa\')', '_buildNavItem(context, 0, Icons.home_rounded, \'Finansal Durum\')')
content = content.replace('_buildNavItem(1, Icons.list_alt_rounded, \'İşlemler\')', '_buildNavItem(context, 1, Icons.list_alt_rounded, \'İşlemler\')')
content = content.replace('_buildNavItem(3, Icons.folder_copy_rounded, \'Projeler\')', '_buildNavItem(context, 3, Icons.folder_copy_rounded, \'Projeler\')')
content = content.replace('_buildNavItem(4, Icons.money_off_rounded, \'Borçlar\')', '_buildNavItem(context, 4, Icons.money_off_rounded, \'Borçlar\')')
content = content.replace('_buildCenterItem(2, Icons.add_rounded)', '_buildCenterItem(context, 2, Icons.add_rounded)')
content = content.replace('Widget _buildCenterItem(int index, IconData icon) {', 'Widget _buildCenterItem(BuildContext context, int index, IconData icon) {')
# Rename Anasayfa to Finansal Durum
content = content.replace("'Anasayfa'", "'Finansal Durum'")
with open(path, 'w', encoding='utf-8') as f: f.write(content)

path2 = r'c:\Users\PC\Desktop\Projeler\hano\lib\views\widgets\zeynep_drawer.dart'
with open(path2, 'r', encoding='utf-8') as f: content2 = f.read()
content2 = content2.replace('package:hano', 'package:hane')
content2 = content2.replace("'Anasayfa'", "'Finansal Durum'")
with open(path2, 'w', encoding='utf-8') as f: f.write(content2)
print('Done')
