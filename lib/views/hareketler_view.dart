import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/views/hareket_detay_view.dart';

class HareketlerView extends StatefulWidget {
  const HareketlerView({super.key});

  @override
  State<HareketlerView> createState() => _HareketlerViewState();
}

class _HareketlerViewState extends State<HareketlerView> {
  final List<String> _filters = ['Tümü', 'Gider', 'Gelir', 'Tahsilat', 'Transfer', 'Avans', 'Maaş', 'Satış'];
  String _selectedFilter = 'Tümü';

  // Dummy transactions data to match the screenshot exactly
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'gider',
      'category': 'GİDER',
      'title': 'Kapıcı Avansı',
      'subtitle': 'Kapıcı Hasan',
      'details': 'Personel Avansı',
      'amount': '₺15.000',
      'date': '10 Mayıs 2024\n11:30',
      'project': 'Akpınar Projesi',
      'account': 'Nakit Kasa',
      'accountIcon': Icons.money_rounded,
    },
    {
      'type': 'gider',
      'category': 'GİDER',
      'title': 'Mehmet Yılmaz Maaş',
      'subtitle': 'Mehmet Yılmaz',
      'details': 'Personel Maaş Ödemesi',
      'amount': '₺50.000',
      'date': '10 Mayıs 2024\n10:15',
      'project': 'Akpınar Projesi',
      'account': 'Halkbank',
      'accountIcon': Icons.account_balance_rounded,
    },
    {
      'type': 'gider',
      'category': 'GİDER',
      'title': 'C30 Hazır Beton',
      'subtitle': 'ABC Beton',
      'details': 'Beton Alımı',
      'amount': '₺250.000',
      'date': '09 Mayıs 2024\n17:20',
      'project': 'Akpınar Projesi',
      'account': 'Halkbank',
      'accountIcon': Icons.account_balance_rounded,
    },
    {
      'type': 'gider',
      'category': 'GİDER',
      'title': '14\'lük Nervürlü Demir',
      'subtitle': 'XYZ Demir',
      'details': 'Demir Alımı',
      'amount': '₺1.450.000',
      'date': '04 Mayıs 2024\n15:40',
      'project': 'Akpınar Projesi',
      'account': 'Halkbank',
      'accountIcon': Icons.account_balance_rounded,
    },
    {
      'type': 'tahsilat',
      'category': 'TAHSİLAT',
      'title': 'Daire Satışı',
      'subtitle': 'Mehmet Yılmaz',
      'details': 'A Blok 12',
      'amount': '₺1.200.000',
      'date': '03 Mayıs 2024\n09:10',
      'project': 'Akpınar Projesi',
      'account': 'Halkbank',
      'accountIcon': Icons.account_balance_rounded,
    },
    {
      'type': 'transfer',
      'category': 'TRANSFER',
      'title': 'Hesaplar Arası Transfer',
      'subtitle': 'Nakit Kasa → Halkbank',
      'details': '',
      'amount': '₺500.000',
      'date': '02 Mayıs 2024\n14:25',
      'project': 'Akpınar Projesi',
      'account': '',
      'accountIcon': null,
    },
    {
      'type': 'gider',
      'category': 'GİDER',
      'title': 'SGK Primi Ödemesi',
      'subtitle': 'Akpınar İnşaat Ltd. Şti.',
      'details': 'SGK Primi',
      'amount': '₺87.500',
      'date': '01 Mayıs 2024\n11:05',
      'project': 'Akpınar Projesi',
      'account': 'Halkbank',
      'accountIcon': Icons.account_balance_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      body: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : context.colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                    backgroundColor: Colors.white,
                    selectedColor: context.colors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? context.colors.brand : context.colors.border,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Search & Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search_rounded, color: context.colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'İşlem ara...',
                              hintStyle: TextStyle(color: context.colors.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, color: context.colors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Filtrele',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Summary Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterCard(context, Icons.calendar_today_rounded, 'Tarih', '01.05.2024 - 31.05.2024'),
                const SizedBox(width: 8),
                _buildFilterCard(context, Icons.folder_open_rounded, 'Proje', 'Tümü'),
                const SizedBox(width: 8),
                _buildFilterCard(context, Icons.person_outline_rounded, 'Cari', 'Tümü'),
                const SizedBox(width: 8),
                _buildFilterCard(context, Icons.sell_outlined, 'Kategori', 'Tümü'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Monthly Summary Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Mayıs 2024',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gelir', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      Text('₺12.450.000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.success)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gider', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      Text('₺8.200.000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.danger)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      Text('₺4.250.000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Transaction List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100), // removed horizontal padding from ListView itself
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => Divider(color: context.colors.border, height: 1),
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionItem(context, transaction);
              },
            ),
          ),
        ],
      ),
      
      // Fixed Bottom Summary Panel
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu Ay Özeti',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Toplam Gelir', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      Text('₺12.450.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.success)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Toplam Gider', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      Text('₺8.200.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.danger)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Net', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      Text('₺4.250.000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.success)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.colors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              Text(value, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> item) {
    Color typeColor;
    IconData typeIcon;
    Color amountColor;
    
    if (item['type'] == 'gider') {
      typeColor = context.colors.danger;
      typeIcon = Icons.arrow_upward_rounded;
      amountColor = context.colors.danger;
    } else if (item['type'] == 'tahsilat') {
      typeColor = context.colors.success;
      typeIcon = Icons.arrow_downward_rounded;
      amountColor = context.colors.success;
    } else { // transfer
      typeColor = context.colors.accent;
      typeIcon = Icons.swap_horiz_rounded;
      amountColor = context.colors.accent;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HareketDetayView(transaction: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          // Main Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                if (item['subtitle'] != null && item['subtitle'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item['subtitle'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                if (item['details'] != null && item['details'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item['details'],
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                // Footer Tags
                Row(
                  children: [
                    Icon(Icons.calendar_view_day_rounded, size: 14, color: context.colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item['project'],
                      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                    ),
                    if (item['account'] != null && item['account'].isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: context.colors.textSecondary)),
                      const SizedBox(width: 8),
                      Icon(item['accountIcon'], size: 14, color: context.colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        item['account'],
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          // Amount & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['amount'],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['date'],
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: context.colors.border),
        ],
      ),
    ),
    );
  }
}
