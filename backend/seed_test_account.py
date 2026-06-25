"""
Test hesabı oluşturma scripti.
Gerçekçi bir inşaat firması verisi ile dolu bir hesap yaratır.
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hano_backend.settings')
django.setup()

from api.models import (
    User, CompanyProfile, Contact, Category, Account, Project,
    BudgetLine, FinancialTransaction, Loan, Cheque, Sale, Receivable,
)
from rest_framework.authtoken.models import Token

# ── 1) Test kullanıcısı oluştur ─────────────────────────────────────────────
TEST_EMAIL = 'test@haneyapim.com'
TEST_PASSWORD = 'Test1234!'

user, created = User.objects.get_or_create(
    email=TEST_EMAIL,
    defaults={'first_name': 'Emre', 'last_name': 'Kılıç'}
)
if created:
    user.set_password(TEST_PASSWORD)
    user.save()
    print(f'✅ Kullanıcı oluşturuldu: {TEST_EMAIL}')
else:
    print(f'ℹ️  Kullanıcı zaten var: {TEST_EMAIL} — veriler sıfırlanıyor.')

token, _ = Token.objects.get_or_create(user=user)

# Eski verileri temizle (kullanıcıya ait)
FinancialTransaction.objects.filter(user=user).delete()
Account.objects.filter(user=user).delete()
Contact.objects.filter(user=user).delete()
Project.objects.filter(user=user).delete()
Category.objects.filter(user=user).delete()
Loan.objects.filter(user=user).delete()
Cheque.objects.filter(user=user).delete()
Sale.objects.filter(user=user).delete()
Receivable.objects.filter(user=user).delete()


# ── 2) Şirket Profili ───────────────────────────────────────────────────────
profile, _ = CompanyProfile.objects.get_or_create(user=user)
profile.company_name = 'Hane Yapım İnşaat Ltd. Şti.'
profile.tax_office = 'Üsküdar V.D.'
profile.tax_number = '7890123456'
profile.commercial_registry = '345678'
profile.mersis_no = '0789012345600018'
profile.address_title = 'Genel Müdürlük'
profile.address_line1 = 'Bağlarbaşı Mah. Kısıklı Cad. No:45'
profile.address_line2 = 'A Blok Kat:7'
profile.city = 'İstanbul'
profile.country = 'Türkiye'
profile.phone1 = '+90 216 987 65 43'
profile.phone2 = '+90 533 876 54 32'
profile.email = 'info@haneyapim.com'
profile.website = 'www.haneyapim.com'
profile.base_currency = 'TRY'
profile.save()
print('✅ Şirket profili güncellendi.')


# ── 3) Varsayılan kategoriler ────────────────────────────────────────────────
from api.default_categories import seed_categories_for_user
seed_categories_for_user(user)
print('✅ Kategoriler yüklendi.')


# ── 4) Cariler (Contacts) ───────────────────────────────────────────────────
contacts_data = [
    {'name': 'Özdemir Beton San.',       'kind': 'supplier',      'phone': '+90 212 333 44 55', 'email': 'satis@ozdemirbeton.com',   'tax_number': '1234567890'},
    {'name': 'Kaya Demir Çelik A.Ş.',    'kind': 'supplier',      'phone': '+90 212 444 55 66', 'email': 'info@kayademir.com.tr',    'tax_number': '2345678901'},
    {'name': 'Yıldız Elektrik Tic.',      'kind': 'supplier',      'phone': '+90 216 555 66 77', 'email': 'siparis@yildizelektrik.com','tax_number': '3456789012'},
    {'name': 'Atlas Hafriyat Ltd.',        'kind': 'supplier',      'phone': '+90 532 111 22 33', 'email': 'atlas@hafriyat.com',       'tax_number': '4567890123'},
    {'name': 'Doğan Tesisat',             'kind': 'subcontractor', 'phone': '+90 535 222 33 44', 'email': 'dogan@tesisat.com',        'tax_number': '5678901234'},
    {'name': 'Güneş Alüminyum',           'kind': 'subcontractor', 'phone': '+90 536 333 44 55', 'email': 'gunes@aluminyum.com',      'tax_number': '6789012345'},
    {'name': 'Mehmet Aydın',              'kind': 'customer',      'phone': '+90 537 444 55 66', 'email': 'mehmet.aydin@gmail.com',   'note': 'B Blok Daire 5 alıcısı'},
    {'name': 'Ayşe Demir',                'kind': 'customer',      'phone': '+90 538 555 66 77', 'email': 'ayse.demir@outlook.com',   'note': 'A Blok Daire 12 alıcısı'},
    {'name': 'Fatma Çelik',               'kind': 'customer',      'phone': '+90 539 666 77 88', 'email': 'fatma.celik@hotmail.com',  'note': 'C Blok Daire 3 alıcısı'},
    {'name': 'Ahmet Yılmaz',              'kind': 'customer',      'phone': '+90 530 777 88 99', 'email': 'ahmet.yilmaz@gmail.com',   'note': 'Dükkan 2 alıcısı'},
    {'name': 'İstanbul Büyükşehir Bld.',  'kind': 'government',    'phone': '+90 212 000 00 00', 'email': 'imar@ibb.gov.tr',          'note': 'İmar ve ruhsat'},
    {'name': 'Üsküdar Vergi Dairesi',     'kind': 'government',    'phone': '+90 216 000 11 11', 'email': 'uskudar@gib.gov.tr',       'note': 'Vergi ödemeleri'},
    {'name': 'Garanti BBVA',              'kind': 'bank',          'phone': '+90 444 0 333',     'email': 'kredi@garantibbva.com.tr', 'note': 'Proje kredisi'},
    {'name': 'Ziraat Bankası',            'kind': 'bank',          'phone': '+90 444 0 110',     'email': 'ticari@ziraatbank.com.tr', 'note': 'KGF kredisi'},
]

contacts = {}
for c in contacts_data:
    obj = Contact.objects.create(user=user, **c)
    contacts[c['name']] = obj
print(f'✅ {len(contacts)} cari hesap oluşturuldu.')


# ── 5) Hesaplar (Accounts) ──────────────────────────────────────────────────
accounts_data = [
    {'name': 'Garanti BBVA TL',   'type': 'Banka',       'currency': 'TRY', 'opening_balance': 3450000.0,  'balance': 3450000.0,  'bank_logo_painter': 'Garanti',   'account_details': 'TR62 0006 2000 1234 0006 2987 45'},
    {'name': 'Ziraat Bankası TL', 'type': 'Banka',       'currency': 'TRY', 'opening_balance': 1780000.0,  'balance': 1780000.0,  'bank_logo_painter': 'Ziraat',    'account_details': 'TR44 0001 0017 4567 0100 1234 56'},
    {'name': 'İş Bankası USD',    'type': 'Banka',       'currency': 'USD', 'opening_balance': 45000.0,    'balance': 45000.0,    'bank_logo_painter': 'IsBankasi', 'account_details': 'TR89 0006 4000 0011 2345 6789 01'},
    {'name': 'Yapı Kredi EUR',    'type': 'Banka',       'currency': 'EUR', 'opening_balance': 22000.0,    'balance': 22000.0,    'bank_logo_painter': 'YapiKredi', 'account_details': 'TR33 0006 7010 0001 0012 3456 78'},
    {'name': 'Şantiye Kasası',    'type': 'Nakit',       'currency': 'TRY', 'opening_balance': 85000.0,    'balance': 85000.0,    'bank_logo_painter': '',           'account_details': 'Nakit'},
    {'name': 'Merkez Kasa',       'type': 'Nakit',       'currency': 'TRY', 'opening_balance': 125000.0,   'balance': 125000.0,   'bank_logo_painter': '',           'account_details': 'Nakit'},
    {'name': 'Garanti Bonus',     'type': 'Kredi Kartı', 'currency': 'TRY', 'opening_balance': 0.0,        'balance': -67500.0,   'credit_limit': 250000.0, 'bank_logo_painter': 'Garanti', 'account_details': '5432 **** **** 7890'},
    {'name': 'Ziraat KGF',        'type': 'BCH',         'currency': 'TRY', 'opening_balance': 0.0,        'balance': -350000.0,  'credit_limit': 2000000.0,'bank_logo_painter': 'Ziraat',  'account_details': 'KGF Cari Hesap'},
]

accounts = {}
for a in accounts_data:
    obj = Account.objects.create(user=user, **a)
    accounts[a['name']] = obj
print(f'✅ {len(accounts)} hesap oluşturuldu.')


# ── 6) Projeler ──────────────────────────────────────────────────────────────
projects_data = [
    {
        'name': 'Bağlarbaşı Konutları',
        'project_code': 'PRJ-001',
        'project_type': 'Konut',
        'status': 'Devam Ediyor',
        'status_color_hex': '0xFF10B981',
        'status_bg_color_hex': '0xFFECFDF5',
        'location': 'Üsküdar, İstanbul',
        'pafta': '45-D-2',
        'parsel': '1234/5',
        'area_sq_meters': 12500,
        'total_independent_sections': 96,
        'unit_count': 88,
        'shop_count': 8,
        'estimated_total_cost': 65000000.0,
        'estimated_total_revenue': 120000000.0,
        'start_date': '2025-03-15',
        'end_date': '2026-12-30',
        'description': '3 blok, 88 daire, 8 dükkan konut projesi',
    },
    {
        'name': 'Kısıklı Rezidans',
        'project_code': 'PRJ-002',
        'project_type': 'Rezidans',
        'status': 'Aktif',
        'status_color_hex': '0xFF3B82F6',
        'status_bg_color_hex': '0xFFEFF6FF',
        'location': 'Üsküdar, İstanbul',
        'pafta': '46-A-1',
        'parsel': '2345/8',
        'area_sq_meters': 8000,
        'total_independent_sections': 64,
        'unit_count': 60,
        'shop_count': 4,
        'estimated_total_cost': 42000000.0,
        'estimated_total_revenue': 85000000.0,
        'start_date': '2025-09-01',
        'end_date': '2027-06-30',
        'description': 'Lüks rezidans projesi — 60 daire, 4 ticari alan',
    },
    {
        'name': 'Çamlıca Villa Evleri',
        'project_code': 'PRJ-003',
        'project_type': 'Villa',
        'status': 'Planlama',
        'status_color_hex': '0xFFF59E0B',
        'status_bg_color_hex': '0xFFFFFBEB',
        'location': 'Çamlıca, İstanbul',
        'pafta': '47-B-3',
        'parsel': '3456/2',
        'area_sq_meters': 18000,
        'total_independent_sections': 16,
        'unit_count': 16,
        'shop_count': 0,
        'estimated_total_cost': 38000000.0,
        'estimated_total_revenue': 72000000.0,
        'start_date': '2026-06-01',
        'end_date': '2027-12-31',
        'description': '16 müstakil villa projesi',
    },
    {
        'name': 'Kadıköy Plaza',
        'project_code': 'PRJ-004',
        'project_type': 'Ticari',
        'status': 'Tamamlandı',
        'status_color_hex': '0xFF8B5CF6',
        'status_bg_color_hex': '0xFFF5F3FF',
        'location': 'Kadıköy, İstanbul',
        'pafta': '42-C-1',
        'parsel': '890/3',
        'area_sq_meters': 6000,
        'total_independent_sections': 30,
        'unit_count': 0,
        'shop_count': 30,
        'estimated_total_cost': 25000000.0,
        'estimated_total_revenue': 52000000.0,
        'start_date': '2024-01-10',
        'end_date': '2025-08-20',
        'description': '30 ofisli iş merkezi — tamamlanmış proje',
    },
]

projects = {}
for p in projects_data:
    obj = Project.objects.create(user=user, **p)
    projects[p['name']] = obj
print(f'✅ {len(projects)} proje oluşturuldu.')


# ── 7) Bütçe Kalemleri ──────────────────────────────────────────────────────
budget_data = [
    # Bağlarbaşı Konutları
    ('Bağlarbaşı Konutları', 'Hafriyat',    2500000),
    ('Bağlarbaşı Konutları', 'Beton',        8000000),
    ('Bağlarbaşı Konutları', 'Demir',        6500000),
    ('Bağlarbaşı Konutları', 'İşçilik',      12000000),
    ('Bağlarbaşı Konutları', 'Elektrik',     3500000),
    ('Bağlarbaşı Konutları', 'Tesisat',      4000000),
    ('Bağlarbaşı Konutları', 'Alüminyum',    5000000),
    ('Bağlarbaşı Konutları', 'İnce İşler',   8500000),
    ('Bağlarbaşı Konutları', 'Peyzaj',       2000000),
    # Kısıklı Rezidans
    ('Kısıklı Rezidans', 'Hafriyat',    1800000),
    ('Kısıklı Rezidans', 'Beton',        5500000),
    ('Kısıklı Rezidans', 'Demir',        4200000),
    ('Kısıklı Rezidans', 'İşçilik',      8000000),
    ('Kısıklı Rezidans', 'Elektrik',     2500000),
    ('Kısıklı Rezidans', 'Tesisat',      3000000),
]

for proj_name, cat, amount in budget_data:
    BudgetLine.objects.create(
        project=projects[proj_name],
        category=cat,
        budgeted_amount=amount,
    )
print(f'✅ {len(budget_data)} bütçe kalemi oluşturuldu.')


# ── 8) Finansal İşlemler ─────────────────────────────────────────────────────
txns = [
    # ─── GİDERLER ───
    # Bağlarbaşı Konutları giderleri
    {'type': 'Gider', 'amount': 1850000, 'date': '2025-04-10', 'category': 'Hafriyat',  'description': 'Temel kazı işleri',              'project': 'Bağlarbaşı Konutları', 'contact': 'Atlas Hafriyat Ltd.',      'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 650000,  'date': '2025-04-18', 'category': 'Hafriyat',  'description': 'Hafriyat nakliye ücreti',         'project': 'Bağlarbaşı Konutları', 'contact': 'Atlas Hafriyat Ltd.',      'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 3200000, 'date': '2025-05-05', 'category': 'Beton',     'description': 'Temel + bodrum beton dökümü',     'project': 'Bağlarbaşı Konutları', 'contact': 'Özdemir Beton San.',       'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 2100000, 'date': '2025-06-12', 'category': 'Beton',     'description': 'Kolon ve perde beton',            'project': 'Bağlarbaşı Konutları', 'contact': 'Özdemir Beton San.',       'from_account': 'Ziraat Bankası TL'},
    {'type': 'Gider', 'amount': 4500000, 'date': '2025-05-20', 'category': 'Demir',     'description': 'İnşaat demiri — 1200 ton',        'project': 'Bağlarbaşı Konutları', 'contact': 'Kaya Demir Çelik A.Ş.',   'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 1800000, 'date': '2025-07-01', 'category': 'Demir',     'description': 'Ek demir siparişi — 480 ton',     'project': 'Bağlarbaşı Konutları', 'contact': 'Kaya Demir Çelik A.Ş.',   'from_account': 'Ziraat Bankası TL'},
    {'type': 'Gider', 'amount': 2800000, 'date': '2025-06-01', 'category': 'İşçilik',   'description': 'Kaba inşaat işçilik (Q2)',        'project': 'Bağlarbaşı Konutları', 'contact': 'Doğan Tesisat',            'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 3500000, 'date': '2025-08-15', 'category': 'İşçilik',   'description': 'İşçilik (Q3)',                    'project': 'Bağlarbaşı Konutları', 'contact': 'Doğan Tesisat',            'from_account': 'Ziraat Bankası TL'},
    {'type': 'Gider', 'amount': 1200000, 'date': '2025-07-20', 'category': 'Elektrik',  'description': 'Elektrik tesisat malzeme + işçilik','project': 'Bağlarbaşı Konutları', 'contact': 'Yıldız Elektrik Tic.',    'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 950000,  'date': '2025-08-10', 'category': 'Tesisat',   'description': 'Su tesisatı ve sıhhi tesisat',    'project': 'Bağlarbaşı Konutları', 'contact': 'Doğan Tesisat',            'from_account': 'Şantiye Kasası'},
    {'type': 'Gider', 'amount': 2200000, 'date': '2025-09-05', 'category': 'Alüminyum', 'description': 'Pencere ve balkon doğrama',        'project': 'Bağlarbaşı Konutları', 'contact': 'Güneş Alüminyum',          'from_account': 'Garanti BBVA TL'},

    # Kısıklı Rezidans giderleri
    {'type': 'Gider', 'amount': 1400000, 'date': '2025-10-01', 'category': 'Hafriyat',  'description': 'Arsa temizleme ve kazı',          'project': 'Kısıklı Rezidans',      'contact': 'Atlas Hafriyat Ltd.',      'from_account': 'Ziraat Bankası TL'},
    {'type': 'Gider', 'amount': 2800000, 'date': '2025-11-15', 'category': 'Beton',     'description': 'Temel beton dökümü',              'project': 'Kısıklı Rezidans',      'contact': 'Özdemir Beton San.',       'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 2100000, 'date': '2025-12-01', 'category': 'Demir',     'description': 'İnşaat demiri — 560 ton',         'project': 'Kısıklı Rezidans',      'contact': 'Kaya Demir Çelik A.Ş.',   'from_account': 'Ziraat Bankası TL'},
    {'type': 'Gider', 'amount': 1600000, 'date': '2026-01-10', 'category': 'İşçilik',   'description': 'Kaba inşaat işçilik',             'project': 'Kısıklı Rezidans',      'contact': 'Doğan Tesisat',            'from_account': 'Garanti BBVA TL'},

    # Genel giderler
    {'type': 'Gider', 'amount': 185000,  'date': '2026-03-15', 'category': 'Vergi',     'description': 'KDV ödemesi (Q1 2026)',           'project': None,                     'contact': 'Üsküdar Vergi Dairesi',    'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 92000,   'date': '2026-04-10', 'category': 'Vergi',     'description': 'SGK primi',                        'project': None,                     'contact': None,                       'from_account': 'Ziraat Bankası TL'},
    {'type': 'Gider', 'amount': 67500,   'date': '2026-05-20', 'category': 'Ofis Gideri', 'description': 'Ofis kirası + faturalar (3 ay)', 'project': None,                     'contact': None,                       'from_account': 'Garanti Bonus'},
    {'type': 'Gider', 'amount': 45000,   'date': '2026-06-01', 'category': 'Araç Yakıt', 'description': 'Araç yakıt ve bakım',             'project': None,                     'contact': None,                       'from_account': 'Şantiye Kasası'},

    # ─── GELİRLER / TAHSİLATLAR ───
    # Daire satış tahsilatları
    {'type': 'Gelir', 'amount': 4500000, 'date': '2025-06-15', 'category': 'Satış',     'description': 'B Blok D5 — peşinat',             'project': 'Bağlarbaşı Konutları', 'contact': 'Mehmet Aydın',   'to_account': 'Garanti BBVA TL'},
    {'type': 'Gelir', 'amount': 3200000, 'date': '2025-07-20', 'category': 'Satış',     'description': 'A Blok D12 — peşinat',            'project': 'Bağlarbaşı Konutları', 'contact': 'Ayşe Demir',     'to_account': 'Garanti BBVA TL'},
    {'type': 'Gelir', 'amount': 2800000, 'date': '2025-09-10', 'category': 'Satış',     'description': 'C Blok D3 — peşinat',             'project': 'Bağlarbaşı Konutları', 'contact': 'Fatma Çelik',    'to_account': 'Ziraat Bankası TL'},
    {'type': 'Gelir', 'amount': 5500000, 'date': '2025-10-05', 'category': 'Satış',     'description': 'Dükkan 2 — tam ödeme',            'project': 'Bağlarbaşı Konutları', 'contact': 'Ahmet Yılmaz',   'to_account': 'Garanti BBVA TL'},
    {'type': 'Gelir', 'amount': 1500000, 'date': '2025-11-15', 'category': 'Satış',     'description': 'B Blok D5 — 2. taksit',           'project': 'Bağlarbaşı Konutları', 'contact': 'Mehmet Aydın',   'to_account': 'Garanti BBVA TL'},
    {'type': 'Gelir', 'amount': 1200000, 'date': '2025-12-20', 'category': 'Satış',     'description': 'A Blok D12 — 2. taksit',          'project': 'Bağlarbaşı Konutları', 'contact': 'Ayşe Demir',     'to_account': 'Ziraat Bankası TL'},
    {'type': 'Gelir', 'amount': 3800000, 'date': '2026-02-01', 'category': 'Satış',     'description': 'Kısıklı Rezidans ön satış (D1)',   'project': 'Kısıklı Rezidans',      'contact': 'Fatma Çelik',    'to_account': 'Garanti BBVA TL'},

    # Kadıköy Plaza gelirleri (tamamlanmış proje)
    {'type': 'Gelir', 'amount': 18000000, 'date': '2024-06-01', 'category': 'Satış',    'description': 'Toplu ofis satışı (15 adet)',      'project': 'Kadıköy Plaza',          'contact': None,             'to_account': 'Garanti BBVA TL'},
    {'type': 'Gelir', 'amount': 22000000, 'date': '2025-02-15', 'category': 'Satış',    'description': 'Kalan ofisler satışı',             'project': 'Kadıköy Plaza',          'contact': None,             'to_account': 'Ziraat Bankası TL'},

    # Borçlanma (kredi kullanımı)
    {'type': 'Borçlanma', 'amount': 5000000,  'date': '2025-04-01', 'category': 'Kredi',  'description': 'Garanti proje kredisi kullanımı', 'project': 'Bağlarbaşı Konutları', 'contact': 'Garanti BBVA',  'to_account': 'Garanti BBVA TL'},
    {'type': 'Borçlanma', 'amount': 3000000,  'date': '2025-09-15', 'category': 'KGF',    'description': 'Ziraat KGF kredisi kullanımı',    'project': 'Kısıklı Rezidans',      'contact': 'Ziraat Bankası','to_account': 'Ziraat Bankası TL'},

    # Haziran 2026 işlemleri (yakın tarihli)
    {'type': 'Gider', 'amount': 380000,  'date': '2026-06-05', 'category': 'Beton',     'description': 'Döşeme betonu — Kat 5',           'project': 'Bağlarbaşı Konutları', 'contact': 'Özdemir Beton San.',  'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 220000,  'date': '2026-06-10', 'category': 'Demir',     'description': 'Kat 5-6 donatı demiri',           'project': 'Bağlarbaşı Konutları', 'contact': 'Kaya Demir Çelik A.Ş.', 'from_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 175000,  'date': '2026-06-15', 'category': 'İşçilik',   'description': 'Haftalık işçilik ödemesi',        'project': 'Bağlarbaşı Konutları', 'contact': None,                  'from_account': 'Şantiye Kasası'},
    {'type': 'Gider', 'amount': 95000,   'date': '2026-06-18', 'category': 'Elektrik',  'description': 'Asansör elektrik bağlantısı',     'project': 'Bağlarbaşı Konutları', 'contact': 'Yıldız Elektrik Tic.','from_account': 'Merkez Kasa'},
    {'type': 'Gelir', 'amount': 1500000, 'date': '2026-06-20', 'category': 'Satış',     'description': 'B Blok D5 — 3. taksit',           'project': 'Bağlarbaşı Konutları', 'contact': 'Mehmet Aydın',        'to_account': 'Garanti BBVA TL'},
    {'type': 'Gider', 'amount': 520000,  'date': '2026-06-22', 'category': 'Tesisat',   'description': 'Doğalgaz tesisatı',               'project': 'Kısıklı Rezidans',      'contact': 'Doğan Tesisat',       'from_account': 'Ziraat Bankası TL'},
]

for t in txns:
    obj_kwargs = {
        'user': user,
        'type': t['type'],
        'amount': t['amount'],
        'date': t['date'],
        'category': t.get('category', ''),
        'description': t.get('description', ''),
        'contact': contacts.get(t.get('contact')) if t.get('contact') else None,
        'contact_name': t.get('contact') or '',
        'project': projects.get(t.get('project')) if t.get('project') else None,
    }
    if t.get('from_account'):
        obj_kwargs['from_account'] = accounts[t['from_account']]
        obj_kwargs['source_name'] = t['from_account']
    if t.get('to_account'):
        obj_kwargs['to_account'] = accounts[t['to_account']]
        obj_kwargs['dest_name'] = t['to_account']

    FinancialTransaction.objects.create(**obj_kwargs)

print(f'✅ {len(txns)} finansal işlem oluşturuldu.')


# ── 9) Krediler ──────────────────────────────────────────────────────────────
loans_data = [
    {
        'name': 'Garanti Proje Kredisi',
        'kind': 'loan',
        'bank_name': 'Garanti BBVA',
        'principal': 5000000,
        'total_payable': 6250000,
        'paid_amount': 1875000,
        'interest_rate': 2.45,
        'term_months': 36,
        'start_date': '2025-04-01',
        'creditor': contacts['Garanti BBVA'],
    },
    {
        'name': 'Ziraat KGF Kredisi',
        'kind': 'kgf',
        'bank_name': 'Ziraat Bankası',
        'principal': 3000000,
        'total_payable': 3540000,
        'paid_amount': 590000,
        'interest_rate': 1.89,
        'term_months': 48,
        'start_date': '2025-09-15',
        'creditor': contacts['Ziraat Bankası'],
    },
]

for l in loans_data:
    Loan.objects.create(user=user, **l)
print(f'✅ {len(loans_data)} kredi oluşturuldu.')


# ── 10) Çekler ───────────────────────────────────────────────────────────────
cheques_data = [
    # Alınan çekler (müşterilerden)
    {'direction': 'received', 'status': 'portfolio',  'amount': 1500000, 'due_date': '2026-08-15', 'bank_name': 'Garanti BBVA',    'serial_no': 'GR-2026-001', 'contact': 'Mehmet Aydın',  'project': 'Bağlarbaşı Konutları'},
    {'direction': 'received', 'status': 'portfolio',  'amount': 1200000, 'due_date': '2026-09-20', 'bank_name': 'İş Bankası',      'serial_no': 'IS-2026-042', 'contact': 'Ayşe Demir',    'project': 'Bağlarbaşı Konutları'},
    {'direction': 'received', 'status': 'deposited',  'amount': 800000,  'due_date': '2026-07-10', 'bank_name': 'Yapı Kredi',       'serial_no': 'YK-2026-115', 'contact': 'Fatma Çelik',   'project': 'Bağlarbaşı Konutları'},
    {'direction': 'received', 'status': 'cashed',     'amount': 2200000, 'due_date': '2026-05-01', 'bank_name': 'Ziraat Bankası',   'serial_no': 'ZR-2026-088', 'contact': 'Ahmet Yılmaz',  'project': 'Bağlarbaşı Konutları'},
    {'direction': 'received', 'status': 'portfolio',  'amount': 1800000, 'due_date': '2026-10-30', 'bank_name': 'Halk Bankası',     'serial_no': 'HB-2026-023', 'contact': 'Fatma Çelik',   'project': 'Kısıklı Rezidans'},

    # Verilen çekler (tedarikçilere)
    {'direction': 'issued', 'status': 'given',       'amount': 950000,  'due_date': '2026-06-30', 'bank_name': 'Garanti BBVA',    'serial_no': 'HY-2026-V01', 'contact': 'Özdemir Beton San.',    'project': 'Bağlarbaşı Konutları'},
    {'direction': 'issued', 'status': 'portfolio',   'amount': 1100000, 'due_date': '2026-08-25', 'bank_name': 'Garanti BBVA',    'serial_no': 'HY-2026-V02', 'contact': 'Kaya Demir Çelik A.Ş.','project': 'Bağlarbaşı Konutları'},
    {'direction': 'issued', 'status': 'portfolio',   'amount': 750000,  'due_date': '2026-09-15', 'bank_name': 'Garanti BBVA',    'serial_no': 'HY-2026-V03', 'contact': 'Güneş Alüminyum',       'project': 'Kısıklı Rezidans'},
]

for ch in cheques_data:
    ch_kwargs = {**ch}
    ch_kwargs['contact'] = contacts.get(ch_kwargs.pop('contact'))
    ch_kwargs['project'] = projects.get(ch_kwargs.pop('project'))
    Cheque.objects.create(user=user, **ch_kwargs)
print(f'✅ {len(cheques_data)} çek oluşturuldu.')


# ── 11) Satışlar ─────────────────────────────────────────────────────────────
sales_data = [
    {'unit_type': 'apartment', 'unit_no': 'B Blok D5',  'sale_price': 9500000,  'sale_date': '2025-06-10', 'buyer': 'Mehmet Aydın',  'project': 'Bağlarbaşı Konutları', 'is_completed': False},
    {'unit_type': 'apartment', 'unit_no': 'A Blok D12', 'sale_price': 8200000,  'sale_date': '2025-07-15', 'buyer': 'Ayşe Demir',    'project': 'Bağlarbaşı Konutları', 'is_completed': False},
    {'unit_type': 'apartment', 'unit_no': 'C Blok D3',  'sale_price': 7800000,  'sale_date': '2025-09-01', 'buyer': 'Fatma Çelik',   'project': 'Bağlarbaşı Konutları', 'is_completed': False},
    {'unit_type': 'shop',      'unit_no': 'Dükkan 2',   'sale_price': 5500000,  'sale_date': '2025-10-01', 'buyer': 'Ahmet Yılmaz',  'project': 'Bağlarbaşı Konutları', 'is_completed': True},
    {'unit_type': 'apartment', 'unit_no': 'D1',         'sale_price': 12000000, 'sale_date': '2026-01-20', 'buyer': 'Fatma Çelik',   'project': 'Kısıklı Rezidans',      'is_completed': False},
]

sales = {}
for s in sales_data:
    s_kwargs = {**s}
    s_kwargs['buyer'] = contacts.get(s_kwargs.pop('buyer'))
    s_kwargs['project'] = projects.get(s_kwargs.pop('project'))
    obj = Sale.objects.create(user=user, **s_kwargs)
    sales[s['unit_no']] = obj
print(f'✅ {len(sales_data)} satış oluşturuldu.')


# ── 12) Alacaklar (Receivables) ──────────────────────────────────────────────
receivables_data = [
    # Mehmet Aydın — B Blok D5 taksitleri
    {'kind': 'installment', 'status': 'collected', 'total_amount': 4500000, 'collected_amount': 4500000, 'due_date': '2025-06-15', 'description': 'Peşinat',         'contact': 'Mehmet Aydın',  'project': 'Bağlarbaşı Konutları', 'sale': 'B Blok D5'},
    {'kind': 'installment', 'status': 'collected', 'total_amount': 1500000, 'collected_amount': 1500000, 'due_date': '2025-11-15', 'description': '2. taksit',        'contact': 'Mehmet Aydın',  'project': 'Bağlarbaşı Konutları', 'sale': 'B Blok D5'},
    {'kind': 'installment', 'status': 'collected', 'total_amount': 1500000, 'collected_amount': 1500000, 'due_date': '2026-06-20', 'description': '3. taksit',        'contact': 'Mehmet Aydın',  'project': 'Bağlarbaşı Konutları', 'sale': 'B Blok D5'},
    {'kind': 'installment', 'status': 'pending',   'total_amount': 2000000, 'collected_amount': 0,       'due_date': '2026-12-15', 'description': 'Son taksit',       'contact': 'Mehmet Aydın',  'project': 'Bağlarbaşı Konutları', 'sale': 'B Blok D5'},

    # Ayşe Demir — A Blok D12
    {'kind': 'installment', 'status': 'collected', 'total_amount': 3200000, 'collected_amount': 3200000, 'due_date': '2025-07-20', 'description': 'Peşinat',         'contact': 'Ayşe Demir',    'project': 'Bağlarbaşı Konutları', 'sale': 'A Blok D12'},
    {'kind': 'installment', 'status': 'collected', 'total_amount': 1200000, 'collected_amount': 1200000, 'due_date': '2025-12-20', 'description': '2. taksit',        'contact': 'Ayşe Demir',    'project': 'Bağlarbaşı Konutları', 'sale': 'A Blok D12'},
    {'kind': 'installment', 'status': 'pending',   'total_amount': 1900000, 'collected_amount': 0,       'due_date': '2026-07-20', 'description': '3. taksit',        'contact': 'Ayşe Demir',    'project': 'Bağlarbaşı Konutları', 'sale': 'A Blok D12'},
    {'kind': 'installment', 'status': 'pending',   'total_amount': 1900000, 'collected_amount': 0,       'due_date': '2027-01-20', 'description': 'Son taksit',       'contact': 'Ayşe Demir',    'project': 'Bağlarbaşı Konutları', 'sale': 'A Blok D12'},

    # Fatma Çelik — C Blok D3
    {'kind': 'installment', 'status': 'collected', 'total_amount': 2800000, 'collected_amount': 2800000, 'due_date': '2025-09-10', 'description': 'Peşinat',         'contact': 'Fatma Çelik',   'project': 'Bağlarbaşı Konutları', 'sale': 'C Blok D3'},
    {'kind': 'installment', 'status': 'overdue',   'total_amount': 2500000, 'collected_amount': 0,       'due_date': '2026-03-10', 'description': '2. taksit (gecikmiş)', 'contact': 'Fatma Çelik',   'project': 'Bağlarbaşı Konutları', 'sale': 'C Blok D3'},
    {'kind': 'installment', 'status': 'pending',   'total_amount': 2500000, 'collected_amount': 0,       'due_date': '2026-09-10', 'description': '3. taksit',        'contact': 'Fatma Çelik',   'project': 'Bağlarbaşı Konutları', 'sale': 'C Blok D3'},

    # Devlet alacağı — hakediş
    {'kind': 'government', 'status': 'pending', 'total_amount': 1500000, 'collected_amount': 0, 'due_date': '2026-08-01', 'description': 'İBB yol katılım payı iadesi', 'contact': 'İstanbul Büyükşehir Bld.', 'project': 'Bağlarbaşı Konutları'},
]

for r in receivables_data:
    r_kwargs = {**r}
    r_kwargs['contact'] = contacts.get(r_kwargs.pop('contact'))
    r_kwargs['project'] = projects.get(r_kwargs.pop('project'))
    sale_key = r_kwargs.pop('sale', None)
    r_kwargs['sale'] = sales.get(sale_key)
    Receivable.objects.create(user=user, **r_kwargs)
print(f'✅ {len(receivables_data)} alacak kaydı oluşturuldu.')


# ── Hesap bakiyelerini yeniden hesapla ───────────────────────────────────────
for acc in Account.objects.filter(user=user):
    acc.recalculate_balance()

print('\n' + '='*60)
print('🎉 TEST HESABI HAZIR!')
print('='*60)
print(f'📧 E-posta : {TEST_EMAIL}')
print(f'🔑 Şifre   : {TEST_PASSWORD}')
print(f'🪙 Token   : {token.key}')
print('='*60)
