"""Mevcut veriyi yeni şemaya taşır (geriye dönük, kayıpsız).

- Her hesabın opening_balance'ını mevcut balance'a eşitler. Böylece hibrit
  recalculate_balance ileride çağrılsa bile görünen bakiye korunur (eski
  işlemler henüz from/to_account'a bağlı olmadığından ledger etkisi 0'dır).
- İşlemlerdeki ayrı kategori isimlerini Category tablosuna aktarır.
- İşlemlerdeki contact_name değerlerinden Contact (cari) kayıtları üretir.
"""
from django.db import migrations


def forwards(apps, schema_editor):
    Account = apps.get_model('api', 'Account')
    Category = apps.get_model('api', 'Category')
    Contact = apps.get_model('api', 'Contact')
    FinancialTransaction = apps.get_model('api', 'FinancialTransaction')

    # 1) opening_balance = mevcut balance
    for acc in Account.objects.all():
        acc.opening_balance = acc.balance
        acc.save(update_fields=['opening_balance'])

    # 2) Kategorileri Category tablosuna taşı (kullanıcı + isim bazlı)
    income_categories = {'Satış', 'Hakediş', 'Kira Geliri', 'Sermaye'}
    seen = set()
    for tx in FinancialTransaction.objects.exclude(category='').only('user_id', 'category', 'type'):
        key = (tx.user_id, tx.category)
        if key in seen:
            continue
        seen.add(key)
        ctype = 'income' if (tx.category in income_categories or tx.type in ('Gelir', 'Tahsilat')) else 'cost'
        Category.objects.get_or_create(
            user_id=tx.user_id, name=tx.category, defaults={'type': ctype}
        )

    # 3) contact_name'lerden Contact üret
    seen_contacts = set()
    for tx in FinancialTransaction.objects.exclude(contact_name='').only('user_id', 'contact_name', 'type'):
        key = (tx.user_id, tx.contact_name)
        if key in seen_contacts:
            continue
        seen_contacts.add(key)
        kind = 'customer' if tx.type in ('Gelir', 'Tahsilat') else 'supplier'
        Contact.objects.get_or_create(
            user_id=tx.user_id, name=tx.contact_name, defaults={'kind': kind}
        )


def backwards(apps, schema_editor):
    # Geri alımda üretilen Category/Contact kayıtları silinebilir; opening_balance kalır.
    Category = apps.get_model('api', 'Category')
    Contact = apps.get_model('api', 'Contact')
    Category.objects.all().delete()
    Contact.objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [
        ('api', '0002_alter_account_options_account_credit_limit_and_more'),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
    ]
