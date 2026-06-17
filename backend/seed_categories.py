# -*- coding: utf-8 -*-
"""Tüm mevcut kullanıcılara varsayılan gelir/gider kategorilerini yükler.

Çalıştırma (backend/):
    venv/Scripts/python.exe seed_categories.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hano_backend.settings')
django.setup()

from api.models import User, Category
from api.default_categories import seed_categories_for_user

for u in User.objects.all():
    created = seed_categories_for_user(u)
    total = Category.objects.filter(user=u).count()
    print(f"{u.email}: +{created} eklendi, toplam {total} kategori")

print("Kategori seed tamam.")
