import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hano_backend.settings')
django.setup()

from api.models import User, Project

user = User.objects.first()
if not user:
    print("No user found. Create a user first.")
    exit(1)

projects = [
    {
        'name': 'Zeynep Konakları',
        'status': 'Aktif',
        'status_color_hex': '0xFF10B981',
        'status_bg_color_hex': '0xFFECFDF5',
        'location': 'Kadıköy, İstanbul',
        'area_sq_meters': 15000,
        'unit_count': 120,
        'shop_count': 10,
        'estimated_total_cost': 45000000.0,
        'estimated_total_revenue': 80000000.0,
    },
    {
        'name': 'Hano İş Merkezi',
        'status': 'Planlama',
        'status_color_hex': '0xFF3B82F6',
        'status_bg_color_hex': '0xFFEFF6FF',
        'location': 'Levent, İstanbul',
        'area_sq_meters': 25000,
        'unit_count': 0,
        'shop_count': 45,
        'estimated_total_cost': 120000000.0,
        'estimated_total_revenue': 200000000.0,
    },
    {
        'name': 'Mavi Yaka Evleri',
        'status': 'Devam Ediyor',
        'status_color_hex': '0xFFF59E0B',
        'status_bg_color_hex': '0xFFFFFBEB',
        'location': 'Karşıyaka, İzmir',
        'area_sq_meters': 8000,
        'unit_count': 40,
        'shop_count': 2,
        'estimated_total_cost': 15000000.0,
        'estimated_total_revenue': 30000000.0,
    },
    {
        'name': 'Yeşil Vadi Villaları',
        'status': 'Tamamlandı',
        'status_color_hex': '0xFF8B5CF6',
        'status_bg_color_hex': '0xFFF5F3FF',
        'location': 'Çankaya, Ankara',
        'area_sq_meters': 12000,
        'unit_count': 24,
        'shop_count': 0,
        'estimated_total_cost': 22000000.0,
        'estimated_total_revenue': 45000000.0,
    }
]

for p in projects:
    Project.objects.get_or_create(
        user=user,
        name=p['name'],
        defaults=p
    )

print("Projects seeded successfully.")
