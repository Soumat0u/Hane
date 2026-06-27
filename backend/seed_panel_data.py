"""user 1 (test@test.com) icin 5 bolumlu finans panelini dolduracak ornek veri.

Calistirma (backend/ klasorunden):
    venv/Scripts/python.exe seed_panel_data.py

Idempotent: once urettigi kayitlari siler, sonra yeniden olusturur. Mevcut
hesap/islem/proje verisine dokunmaz (sadece credit_limit/yeni hesap ekler).
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hano_backend.settings')
django.setup()

from api.models import (
    User, Account, Contact, Loan, Cheque, Sale, Receivable, BudgetLine, Project,
)

u = User.objects.get(id=1)
projects = list(Project.objects.filter(user=u))
proj = {p.name: p for p in projects}
first_proj = projects[0] if projects else None

print("Seed başlıyor — kullanıcı:", u.email)

# ── Temizlik (yeniden çalıştırılabilir olsun) ─────────────────────────────────
Loan.objects.filter(user=u).delete()
Cheque.objects.filter(user=u).delete()
Receivable.objects.filter(user=u).delete()
Sale.objects.filter(user=u).delete()
Contact.objects.filter(user=u, note='seed').delete()
Account.objects.filter(user=u, account_details='seed').delete()

# ── 1. KASA — Borsa hesabı + BCH hesapları + kart limiti ──────────────────────
Account.objects.create(
    user=u, name='Yatırım (Borsa)', type=Account.BROKERAGE,
    opening_balance=320000, balance=320000, account_details='seed',
)
# BCH: negatif bakiye = kullanılan; credit_limit = toplam tahsis
Account.objects.create(
    user=u, name='Halkbank BCH', type=Account.BCH,
    opening_balance=-1800000, balance=-1800000, credit_limit=2500000, account_details='seed',
)
Account.objects.create(
    user=u, name='Ziraat BCH', type=Account.BCH,
    opening_balance=-1200000, balance=-1200000, credit_limit=1750000, account_details='seed',
)
# Mevcut kredi kartına limit ata → kullanılabilir kart limiti
card = Account.objects.filter(user=u, type=Account.CREDIT_CARD).first()
if card:
    card.credit_limit = 150000
    card.save(update_fields=['credit_limit'])

# ── Cari hesaplar (tedarikçiler / müşteriler / devlet) ────────────────────────
def contact(name, kind):
    return Contact.objects.create(user=u, name=name, kind=kind, note='seed')

demirci = contact('Demirci Mehmet', Contact.SUPPLIER)
betoncu = contact('Beton A.Ş.', Contact.SUPPLIER)
kalipci = contact('Kalıpçı Hasan', Contact.SUBCONTRACTOR)
elektrik = contact('Elektrikçi Ali', Contact.SUBCONTRACTOR)
taseron = contact('Yıldız Taşeron', Contact.SUBCONTRACTOR)
musteri1 = contact('Ayşe Demir', Contact.CUSTOMER)
musteri2 = contact('Kaya İnşaat', Contact.CUSTOMER)
devlet = contact('Vergi Dairesi (KDV İade)', Contact.GOVERNMENT)

# ── 2. BORÇLAR — Krediler + KGF + Çekler ──────────────────────────────────────
Loan.objects.create(
    user=u, name='İşletme Kredisi', kind=Loan.LOAN, bank_name='Garanti BBVA',
    principal=2500000, total_payable=2950000, paid_amount=450000,
    interest_rate=42.0, term_months=24, start_date='2025-09-01',
)
Loan.objects.create(
    user=u, name='KGF Kredisi', kind=Loan.KGF, bank_name='Ziraat Bankası',
    principal=750000, total_payable=820000, paid_amount=70000,
    interest_rate=28.0, term_months=36, start_date='2026-01-15',
)

# Çekler — verilen (borç) ve alınan (alacak)
Cheque.objects.create(user=u, direction=Cheque.ISSUED, status=Cheque.PORTFOLIO,
                      amount=650000, due_date='2026-07-20',
                      bank_name='Garanti BBVA', serial_no='0012345', contact=betoncu,
                      project=first_proj)
Cheque.objects.create(user=u, direction=Cheque.ISSUED, status=Cheque.PORTFOLIO,
                      amount=500000, due_date='2026-08-10',
                      bank_name='İş Bankası', serial_no='0012346', contact=demirci)
Cheque.objects.create(user=u, direction=Cheque.RECEIVED, status=Cheque.PORTFOLIO,
                      amount=900000, due_date='2026-07-05',
                      bank_name='Ziraat', serial_no='0099001', contact=musteri2)

# ── 4. PROJE MALİYETLERİ — bütçe kalemleri (gerçekleşme için) ─────────────────
budget_categories = {
    'Hafriyat': 320000, 'Demir': 980000, 'Beton': 1150000, 'Kalıp': 420000,
    'Yalıtım': 260000, 'İşçilik': 870000, 'Diğer': 190000,
}
if first_proj:
    for cat, amount in budget_categories.items():
        BudgetLine.objects.update_or_create(
            project=first_proj, category=cat,
            defaults={'budgeted_amount': amount},
        )

# ── 5. ALACAKLAR — Satışlar + taksitler + müşteri/devlet alacağı ──────────────
sale1 = Sale.objects.create(
    user=u, project=first_proj, buyer=musteri1, unit_type=Sale.APARTMENT,
    unit_no='A-12', sale_price=4200000, sale_date='2026-03-10',
)
sale2 = Sale.objects.create(
    user=u, project=first_proj, buyer=musteri2, unit_type=Sale.SHOP,
    unit_no='D-3', sale_price=1850000, sale_date='2026-04-02',
)

# Satış taksitleri (vadeli tahsilatlar)
Receivable.objects.create(user=u, kind=Receivable.SALE_INSTALLMENT, sale=sale1,
                          contact=musteri1, project=first_proj, total_amount=2200000,
                          collected_amount=800000, due_date='2026-07-15',
                          status=Receivable.PARTIAL, description='A-12 daire taksiti')
Receivable.objects.create(user=u, kind=Receivable.SALE_INSTALLMENT, sale=sale2,
                          contact=musteri2, project=first_proj, total_amount=1850000,
                          collected_amount=0, due_date='2026-09-01',
                          status=Receivable.PENDING, description='D-3 dükkan bedeli')
# Müşteri ve devlet alacağı
Receivable.objects.create(user=u, kind=Receivable.CUSTOMER, contact=musteri1,
                          total_amount=1340000, collected_amount=0,
                          due_date='2026-08-20', description='Müşteri cari alacağı')
Receivable.objects.create(user=u, kind=Receivable.GOVERNMENT, contact=devlet,
                          total_amount=680000, collected_amount=0,
                          due_date='2026-10-01', description='KDV iadesi')

print("Hesaplar     :", Account.objects.filter(user=u).count())
print("Cariler      :", Contact.objects.filter(user=u).count())
print("Krediler     :", Loan.objects.filter(user=u).count())
print("Çekler       :", Cheque.objects.filter(user=u).count())
print("Satışlar     :", Sale.objects.filter(user=u).count())
print("Alacaklar    :", Receivable.objects.filter(user=u).count())
print("Bütçe kalemi :", BudgetLine.objects.filter(project__user=u).count())
print("Seed tamam.")
