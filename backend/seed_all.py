import os
import django
import random
from datetime import datetime, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hano_backend.settings')
django.setup()

from api.models import User, CompanyProfile, Account, Project, FinancialTransaction

user = User.objects.first()
if not user:
    print("No user found. Create a user first.")
    exit(1)

# Seed Company Profile
profile, created = CompanyProfile.objects.get_or_create(
    user=user,
    defaults={
        'company_name': 'Zeynep İnşaat A.Ş.',
        'tax_office': 'Kadıköy V.D.',
        'tax_number': '1234567890',
        'commercial_registry': '987654321',
        'mersis_no': '0123456789000015',
        'address_title': 'Merkez Ofis',
        'address_line1': 'Caferağa Mah. Moda Cad. No:12',
        'address_line2': 'Kat: 3 Daire: 5',
        'city': 'İstanbul',
        'country': 'Türkiye',
        'phone1': '+90 216 123 45 67',
        'phone2': '+90 532 123 45 67',
        'email': 'info@zeynepinsaat.com.tr'
    }
)

if not created:
    profile.company_name = 'Zeynep İnşaat A.Ş.'
    profile.tax_office = 'Kadıköy V.D.'
    profile.tax_number = '1234567890'
    profile.commercial_registry = '987654321'
    profile.mersis_no = '0123456789000015'
    profile.address_title = 'Merkez Ofis'
    profile.address_line1 = 'Caferağa Mah. Moda Cad. No:12'
    profile.address_line2 = 'Kat: 3 Daire: 5'
    profile.city = 'İstanbul'
    profile.country = 'Türkiye'
    profile.phone1 = '+90 216 123 45 67'
    profile.phone2 = '+90 532 123 45 67'
    profile.email = 'info@zeynepinsaat.com.tr'
    profile.save()

# Seed Accounts
accounts = [
    {'name': 'Garanti BBVA', 'type': 'Banka', 'balance': 2500000.0, 'bank_logo_painter': 'Garanti', 'account_details': 'TR12 0006 2000 0001 2345 6789 01'},
    {'name': 'İş Bankası', 'type': 'Banka', 'balance': 1850000.0, 'bank_logo_painter': 'IsBankasi', 'account_details': 'TR34 0006 4000 0001 2345 6789 02'},
    {'name': 'Ziraat Bankası', 'type': 'Banka', 'balance': 3200000.0, 'bank_logo_painter': 'Ziraat', 'account_details': 'TR56 0001 0000 0001 2345 6789 03'},
    {'name': 'Merkez Kasa', 'type': 'Nakit', 'balance': 150000.0, 'bank_logo_painter': '', 'account_details': 'Nakit Kasa'},
    {'name': 'Garanti Bonus', 'type': 'Kredi Kartı', 'balance': -45000.0, 'bank_logo_painter': 'Garanti', 'account_details': '5432 **** **** 1234'}
]

for acc in accounts:
    Account.objects.get_or_create(
        user=user,
        name=acc['name'],
        defaults=acc
    )

# Seed Projects (just in case they don't exist)
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

all_projects = list(Project.objects.filter(user=user))

# Seed Financial Transactions
# Delete existing transactions
FinancialTransaction.objects.filter(user=user).delete()

categories_income = ['Hakediş', 'Satış', 'Kira Geliri', 'Sermaye']
categories_expense = ['Beton', 'Demir', 'Personel', 'Vergi', 'Nalburiye', 'Hafriyat', 'Araç Yakıt', 'Pazarlama']

today = datetime.now()

for i in range(25):
    is_income = random.choice([True, False])
    if is_income:
        t_type = 'Gelir'
        category = random.choice(categories_income)
        amount = round(random.uniform(50000, 500000), 2)
    else:
        t_type = 'Gider'
        category = random.choice(categories_expense)
        amount = round(random.uniform(5000, 150000), 2)
        
    date = today - timedelta(days=random.randint(0, 60))
    date_str = date.strftime('%Y-%m-%d')
    due_date_str = (date + timedelta(days=random.randint(0, 30))).strftime('%Y-%m-%d')
    
    project = random.choice(all_projects) if random.random() > 0.3 else None
    
    FinancialTransaction.objects.create(
        user=user,
        project=project,
        type=t_type,
        amount=amount,
        date=date_str,
        category=category,
        description=f'{category} ödemesi/tahsilatı',
        source_name='Merkez Kasa' if not is_income else 'Müşteri/Kurum',
        dest_name='Tedarikçi' if not is_income else 'Merkez Kasa',
        contact_name='Ahmet Yılmaz',
        due_date=due_date_str
    )

print("All dummy data seeded successfully.")
