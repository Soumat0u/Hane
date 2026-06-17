from django.contrib import admin
from .models import User, CompanyProfile, Account, Project, FinancialTransaction

admin.site.register(User)
admin.site.register(CompanyProfile)
admin.site.register(Account)
admin.site.register(Project)
admin.site.register(FinancialTransaction)
