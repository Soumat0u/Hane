from django.core.management.base import BaseCommand

from api.models import RecurringTransaction


class Command(BaseCommand):
    help = 'Vadesi gelmiş tüm tekrarlayan işlem şablonlarını otomatik onaylar (tüm kullanıcılar).'

    def handle(self, *args, **options):
        created = RecurringTransaction.auto_confirm_due()
        self.stdout.write(self.style.SUCCESS(f'{len(created)} işlem otomatik oluşturuldu.'))
