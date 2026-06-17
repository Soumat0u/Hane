# -*- coding: utf-8 -*-
"""İnşaat firması için varsayılan gelir/gider kategorileri (gruplu).

Yeni kullanıcı kaydolurken ve mevcut kullanıcılara seed yoluyla yüklenir.
Format: (group, name, type)  →  type: 'income' | 'cost'
"""

DEFAULT_CATEGORIES = [
    # ── GELİRLER ──────────────────────────────────────────────────────────────
    ('Ana Gelir', 'Daire / Dükkan Satışı', 'income'),
    ('Ana Gelir', 'Kat Karşılığı Bağımsız Bölüm', 'income'),
    ('Ana Gelir', 'Anahtar Teslim İnşaat Bedeli', 'income'),
    ('Ana Gelir', 'Kamu İhalesi Hakedişi', 'income'),
    ('Ana Gelir', 'Tadilat / Güçlendirme / Yenileme', 'income'),
    ('Ek Gelir', 'İş Makinesi Kiralama', 'income'),
    ('Ek Gelir', 'Artık Malzeme Satışı', 'income'),

    # ── GİDERLER ──────────────────────────────────────────────────────────────
    # Malzeme
    ('Malzeme', 'Beton / Hazır Beton', 'cost'),
    ('Malzeme', 'İnşaat Demiri / Profil Çelik', 'cost'),
    ('Malzeme', 'Tuğla / Blok / Ytong', 'cost'),
    ('Malzeme', 'Alçı / Alçıpan / Sıva', 'cost'),
    ('Malzeme', 'Seramik / Fayans / Parke', 'cost'),
    ('Malzeme', 'Kapı / Pencere / Doğrama', 'cost'),
    ('Malzeme', 'Boya / Yalıtım Malzemeleri', 'cost'),
    ('Malzeme', 'Sıhhi Tesisat & Elektrik Malzemesi', 'cost'),
    # İşçilik & Taşeron
    ('İşçilik & Taşeron', 'Kalıp / Demir / Sıva / Alçı Ekipleri', 'cost'),
    ('İşçilik & Taşeron', 'Elektrik & Tesisat Taşeronu', 'cost'),
    ('İşçilik & Taşeron', 'Karot / Demir / Çatı Ustaları', 'cost'),
    ('İşçilik & Taşeron', 'Şantiye Şefi / Tekniker Maaşı', 'cost'),
    ('İşçilik & Taşeron', 'Yevmiyeli Günlük İşçi', 'cost'),
    # Makine & Ekipman
    ('Makine & Ekipman', 'Vinç / Beton Pompası / Forklift Kiralama', 'cost'),
    ('Makine & Ekipman', 'Kazıcı / Kepçe / Kamyon Kiralama', 'cost'),
    ('Makine & Ekipman', 'Küçük Ekipman', 'cost'),
    ('Makine & Ekipman', 'Makine Yakıt / Bakım / Sigorta', 'cost'),
    # Şantiye
    ('Şantiye', 'Şantiye Elektrik & Su', 'cost'),
    ('Şantiye', 'Geçici Kulübe / Tuvalet / Çit', 'cost'),
    ('Şantiye', 'Şantiye Güvenliği', 'cost'),
    ('Şantiye', 'Nakliye / Malzeme Taşıma', 'cost'),
    # İdari
    ('İdari', 'Ofis Kira & Faturaları', 'cost'),
    ('İdari', 'Muhasebeci / Mali Müşavir', 'cost'),
    ('İdari', 'Araç Giderleri', 'cost'),
    ('İdari', 'Telefon & İnternet', 'cost'),
    ('İdari', 'İhale Teklif Hazırlık', 'cost'),
    # Yasal & Resmi
    ('Yasal & Resmi', 'SGK Primleri', 'cost'),
    ('Yasal & Resmi', 'Vergiler (Gelir / Kurumlar / KDV / Damga)', 'cost'),
    ('Yasal & Resmi', 'Yapı Ruhsatı / İskan Harçları', 'cost'),
    ('Yasal & Resmi', 'Yapı Denetim Ücreti', 'cost'),
    ('Yasal & Resmi', 'Teminat Mektubu Komisyonu', 'cost'),
    ('Yasal & Resmi', 'Geçici Teminat Kesintisi', 'cost'),
    # Sigorta
    ('Sigorta', 'İnşaat All Risk Sigortası', 'cost'),
    ('Sigorta', 'İşçi Kaza / İşveren Sorumluluk', 'cost'),
    ('Sigorta', 'Araç Sigortası', 'cost'),
    # Finansman
    ('Finansman', 'Banka Kredisi Faizi', 'cost'),
    ('Finansman', 'Kısa Vadeli Nakit Açığı Kredisi', 'cost'),
    ('Finansman', 'Tedarikçi Vadeli Borç Faizi', 'cost'),
]

# Kullanıcının mevcut masaüstü yazılımındaki proje "ANA KATEGORİ" listesi
# (iki ekran görüntüsünden alındı). Proje masraf kalemleri olarak eklenir.
PROJECT_MAIN_CATEGORIES = [
    'Yalıtım', 'Kereste', 'Proje', 'Noter', 'Resmiyet / Belediye', 'Banka',
    'Hisse Alımı', 'Kırtasiye', 'Jeoloji', 'Harita', 'Belediye', 'Yapı Denetim',
    'Elektrik', 'Hafriyat', 'Demirbaş', 'Demir', 'Kalıp', 'Beton', 'Nakliye',
    'Şirket', 'Rüşvet', 'Personel', 'Tesisat', 'Ekstra İşçilik', 'Duvar',
    'Pen Doğrama', 'Dış Cephe File / Güvenlik', 'Asansör', 'Ekstra İnşaat Giderleri',
    'Demir Doğrama', 'Sıva', 'Tavan / Alçı Dekor', 'Mermer', 'Mobilya', 'Seramik',
    'Alüminyum - Krom', 'Reklam', 'Şap', 'Çelik Kapı', 'Hırdavat', 'Parke',
    'Boya', 'Doğalgaz', 'Çevre Düzenleme',
]

# Proje masraf kategorilerini ortak grup altında tabloya ekle
DEFAULT_CATEGORIES = DEFAULT_CATEGORIES + [
    ('Proje Masrafı', name, 'cost') for name in PROJECT_MAIN_CATEGORIES
]


def seed_categories_for_user(user):
    """Kullanıcıda eksik olan varsayılan kategorileri ekler (isimde varsa atlar)."""
    from .models import Category

    created = 0
    for group, name, ctype in DEFAULT_CATEGORIES:
        obj, was_created = Category.objects.get_or_create(
            user=user, name=name, parent=None, defaults={'type': ctype, 'group': group}
        )
        if was_created:
            created += 1
        elif not obj.group:
            # Mevcut (taşımadan gelen) kategoriye grup/type bilgisini tamamla
            obj.group = group
            obj.type = ctype
            obj.save(update_fields=['group', 'type'])
    return created
