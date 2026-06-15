import 'package:flutter/material.dart';

class BildirimlerView extends StatelessWidget {
  const BildirimlerView({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy notification data
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Ödeme Hatırlatması',
        'message': 'Akpınar Projesi için C25 beton ödemesinin vadesi yarın doluyor.',
        'time': '10 Dk Önce',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFF7ED),
        'isRead': false,
      },
      {
        'title': 'Yeni Tahsilat',
        'message': 'Mehmet Yılmaz\'dan 1.200.000 ₺ tahsilat alındı.',
        'time': '2 Saat Önce',
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFF0FDF4),
        'isRead': false,
      },
      {
        'title': 'Proje Durum Güncellemesi',
        'message': 'Sarayatik Projesi "Ruhsat Aşaması"ndan "Temel Aşamasında" durumuna geçti.',
        'time': 'Dün',
        'icon': Icons.info_outline,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'isRead': true,
      },
      {
        'title': 'Sistem',
        'message': 'Haftalık finansal özet raporunuz hazırlandı. Görmek için dokunun.',
        'time': '2 Gün Önce',
        'icon': Icons.assessment_outlined,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
        'isRead': true,
      },
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Bildirimler',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tümü okundu olarak işaretlendi.')),
                        );
                      },
                      child: const Text('Tümünü Oku', style: TextStyle(color: Color(0xFF032B5E), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: notif['isRead'] ? Colors.white : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notif['isRead'] ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                      ),
                      boxShadow: notif['isRead'] ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: notif['bg'],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(notif['icon'], color: notif['color'], size: 22),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'],
                              style: TextStyle(
                                fontWeight: notif['isRead'] ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Text(
                            notif['time'],
                            style: TextStyle(
                              fontSize: 11,
                              color: notif['isRead'] ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontWeight: notif['isRead'] ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          notif['message'],
                          style: TextStyle(
                            fontSize: 13,
                            color: notif['isRead'] ? const Color(0xFF64748B) : const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
