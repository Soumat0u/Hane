from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.db.models import Sum
from decimal import Decimal


class UserManager(BaseUserManager):
    """Custom user manager where email is the unique identifier."""

    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('E-posta adresi zorunludur.')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """Custom user model with email as the login field."""
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.email


class CompanyProfile(models.Model):
    """Company profile - one per user."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='company_profile')
    company_name = models.CharField(max_length=255, default='', blank=True)
    tax_office = models.CharField(max_length=255, default='', blank=True)
    tax_number = models.CharField(max_length=50, default='', blank=True)
    commercial_registry = models.CharField(max_length=50, default='', blank=True)
    mersis_no = models.CharField(max_length=50, default='', blank=True)
    address_title = models.CharField(max_length=255, default='', blank=True)
    address_line1 = models.CharField(max_length=255, default='', blank=True)
    address_line2 = models.CharField(max_length=255, default='', blank=True)
    city = models.CharField(max_length=100, default='', blank=True)
    country = models.CharField(max_length=100, default='', blank=True)
    phone1 = models.CharField(max_length=30, default='', blank=True)
    phone2 = models.CharField(max_length=30, default='', blank=True)
    email = models.CharField(max_length=255, default='', blank=True)
    website = models.CharField(max_length=255, default='', blank=True)
    read_notifications = models.TextField(default='', blank=True)
    logo = models.FileField(upload_to='company_logos/', null=True, blank=True)

    def __str__(self):
        return self.company_name or f'Profile of {self.user.email}'


class Contact(models.Model):
    """Cari hesap: tedarikçi, müşteri, taşeron, devlet vb."""
    SUPPLIER = 'supplier'
    CUSTOMER = 'customer'
    SUBCONTRACTOR = 'subcontractor'
    GOVERNMENT = 'government'
    BANK = 'bank'
    OTHER = 'other'
    KIND_CHOICES = [
        (SUPPLIER, 'Tedarikçi'),
        (CUSTOMER, 'Müşteri'),
        (SUBCONTRACTOR, 'Taşeron'),
        (GOVERNMENT, 'Devlet'),
        (BANK, 'Banka'),
        (OTHER, 'Diğer'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='contacts')
    name = models.CharField(max_length=255)
    kind = models.CharField(max_length=20, choices=KIND_CHOICES, default=OTHER)
    phone = models.CharField(max_length=30, default='', blank=True)
    email = models.CharField(max_length=255, default='', blank=True)
    tax_number = models.CharField(max_length=50, default='', blank=True)
    note = models.CharField(max_length=500, default='', blank=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f'{self.name} ({self.get_kind_display()})'

    @property
    def balance(self):
        """Cariye olan borç/alacak: (giden - gelen) işlemlerden türetilir.
        Pozitif = bizim borcumuz, negatif = bizden alacak (yaklaşık)."""
        incoming = self.transactions.filter(type='Gelir').aggregate(s=Sum('amount'))['s'] or 0
        outgoing = self.transactions.filter(type='Gider').aggregate(s=Sum('amount'))['s'] or 0
        return outgoing - incoming


class Category(models.Model):
    """Maliyet/gelir kategorisi (Hafriyat, Demir, Beton, Satış vb.). Kullanıcı bazlı."""
    COST = 'cost'
    INCOME = 'income'
    TYPE_CHOICES = [(COST, 'Maliyet'), (INCOME, 'Gelir')]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='categories')
    name = models.CharField(max_length=100)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default=COST)
    group = models.CharField(max_length=100, default='', blank=True)  # ana kategori grubu (Malzeme, Proje Masrafı...)
    # Alt kategori ise üst (ana) kategoriye işaret eder; ana kategoride null'dır.
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='children')

    class Meta:
        ordering = ['group', 'name']
        unique_together = ('user', 'parent', 'name')

    def __str__(self):
        return f'{self.parent.name} / {self.name}' if self.parent else self.name

    @property
    def is_main(self):
        return self.parent_id is None


class Account(models.Model):
    """Kasa hesabı: banka, nakit, borsa, kredi kartı, BCH (banka cari hesap), esnek hesap.

    Hibrit bakiye: ``balance`` saklanır (hızlı okuma) ama ``recalculate_balance``
    ile ledger'dan (opening_balance + gelen - giden) yeniden hesaplanabilir.
    """
    BANK = 'Banka'
    CASH = 'Nakit'
    BROKERAGE = 'Borsa'
    CREDIT_CARD = 'Kredi Kartı'
    BCH = 'BCH'
    FLEXIBLE = 'Esnek'
    TYPE_CHOICES = [
        (BANK, 'Banka'),
        (CASH, 'Nakit'),
        (BROKERAGE, 'Borsa'),
        (CREDIT_CARD, 'Kredi Kartı'),
        (BCH, 'Banka Cari Hesap'),
        (FLEXIBLE, 'Esnek Hesap'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='accounts')
    name = models.CharField(max_length=255)
    type = models.CharField(max_length=50, choices=TYPE_CHOICES, default=BANK)

    opening_balance = models.FloatField(default=0.0)
    balance = models.FloatField(default=0.0)  # cache: güncel bakiye (hesabın para biriminde)
    # Kullanılabilir limit (kredi kartı / BCH / esnek hesap için) → Finansman Gücü
    credit_limit = models.FloatField(default=0.0)

    bank_logo_painter = models.CharField(max_length=255, default='')
    account_details = models.CharField(max_length=255, default='')  # IBAN / kart no
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f'{self.name} ({self.type})'

    def recalculate_balance(self, save=True):
        """Ledger'dan güncel bakiyeyi yeniden hesaplar (hibrit yaklaşım: FK'lı +
        isim eşleşmeli/legacy işlemler birlikte). Hesap hem FK'lı hem isim-bazlı
        işlemlere sahip olabildiği için (örn. tekrarlayan işlem onayı FK kullanır,
        normal giriş ekranları isim kullanır), ikisi de dahil edilmezse biri
        diğerini sessizce sıfırlar."""
        incoming = self.incoming_transactions.aggregate(s=Sum('amount'))['s'] or 0
        outgoing = self.outgoing_transactions.aggregate(s=Sum('amount'))['s'] or 0

        legacy_qs = FinancialTransaction.objects.filter(
            user=self.user, from_account__isnull=True, to_account__isnull=True,
        ).filter(models.Q(source_name=self.name) | models.Q(dest_name=self.name))
        for t in legacy_qs:
            if t.type == 'Gider':
                outgoing += t.amount
            elif t.type in ('Gelir', 'Tahsilat', 'Kredi Kullanımı'):
                incoming += t.amount
            elif t.type == 'Transfer':
                if t.source_name == self.name:
                    outgoing += t.amount
                if t.dest_name == self.name:
                    incoming += t.amount

        self.balance = (self.opening_balance or 0) + incoming - outgoing
        if save:
            self.save(update_fields=['balance'])
        return self.balance

    @property
    def available_limit(self):
        """Kullanılabilir limit = limit - kullanılan (negatif bakiyenin mutlak değeri)."""
        if self.type in (self.CREDIT_CARD, self.BCH, self.FLEXIBLE):
            used = abs(self.balance) if self.balance < 0 else 0
            return max((self.credit_limit or 0) - used, 0)
        return 0


class Project(models.Model):
    """Construction project."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='projects')
    name = models.CharField(max_length=255)
    project_code = models.CharField(max_length=50, default='', blank=True)
    project_type = models.CharField(max_length=100, default='Konut', blank=True)
    status = models.CharField(max_length=100)
    status_color_hex = models.CharField(max_length=10)
    status_bg_color_hex = models.CharField(max_length=10)
    location = models.CharField(max_length=255, default='')
    pafta = models.CharField(max_length=100, default='', blank=True)
    parsel = models.CharField(max_length=100, default='', blank=True)
    area_sq_meters = models.IntegerField(default=0)
    total_independent_sections = models.IntegerField(default=0)
    unit_count = models.IntegerField(default=0)
    shop_count = models.IntegerField(default=0)
    estimated_total_cost = models.FloatField(default=0.0)
    estimated_total_revenue = models.FloatField(default=0.0)
    image_path = models.FileField(upload_to='project_images/', max_length=500, blank=True, null=True)
    start_date = models.CharField(max_length=50, default='', blank=True)
    end_date = models.CharField(max_length=50, default='', blank=True)
    description = models.TextField(default='', blank=True)

    def __str__(self):
        return self.name

    def total_spent(self):
        return self.transactions.filter(type='Gider').aggregate(s=Sum('amount'))['s'] or 0

    def total_collected(self):
        return self.transactions.filter(type__in=['Tahsilat', 'Gelir']).aggregate(s=Sum('amount'))['s'] or 0


class ProjectDocument(models.Model):
    """Projeye ait belge (plan, sözleşme, ruhsat vb.). FinancialTransaction.attachment ile aynı desen."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='project_documents')
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='documents')
    name = models.CharField(max_length=255, default='', blank=True)
    file = models.FileField(upload_to='project_docs/%Y/%m/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-uploaded_at']

    def __str__(self):
        return self.name or self.file.name


class BudgetLine(models.Model):
    """Proje bütçe kalemi: kategori bazında planlanan tutar (gerçekleşme ile karşılaştırılır)."""
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='budget_lines')
    category = models.CharField(max_length=100)  # Hafriyat, Demir, Beton, İşçilik...
    budgeted_amount = models.FloatField(default=0.0)

    class Meta:
        ordering = ['category']
        unique_together = ('project', 'category')

    def __str__(self):
        return f'{self.project.name} / {self.category}'

    def actual_amount(self):
        return self.project.transactions.filter(
            type='Gider', category=self.category
        ).aggregate(s=Sum('amount'))['s'] or 0


class FinancialTransaction(models.Model):
    """Finansal işlem (ledger kaydı).

    ``from_account`` (para çıkışı) ve ``to_account`` (para girişi) hesapların
    bakiyesini etkiler. ``source_name``/``dest_name`` denormalize (eski uyumluluk).
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions')
    type = models.CharField(max_length=50)  # Gelir, Gider, Tahsilat, Transfer, Borçlanma...
    amount = models.FloatField()
    date = models.CharField(max_length=50)
    category = models.CharField(max_length=100, default='', blank=True)
    description = models.CharField(max_length=500, default='', blank=True)
    quantity = models.FloatField(default=0.0, blank=True, null=True)
    unit = models.CharField(max_length=50, default='', blank=True)

    # Ledger bağlantıları
    from_account = models.ForeignKey(Account, on_delete=models.SET_NULL, null=True, blank=True, related_name='outgoing_transactions')
    to_account = models.ForeignKey(Account, on_delete=models.SET_NULL, null=True, blank=True, related_name='incoming_transactions')
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions')
    loan = models.ForeignKey('Loan', on_delete=models.SET_NULL, null=True, blank=True, related_name='payments')
    cheque = models.ForeignKey('Cheque', on_delete=models.SET_NULL, null=True, blank=True, related_name='payments')

    # Eski uyumluluk (denormalize) + serbest metin
    source_name = models.CharField(max_length=255, default='', blank=True)
    dest_name = models.CharField(max_length=255, default='', blank=True)
    contact_name = models.CharField(max_length=255, default='', blank=True)
    document_no = models.CharField(max_length=100, default='', blank=True)
    due_date = models.CharField(max_length=50, default='', blank=True)
    attachment = models.FileField(upload_to='attachments/%Y/%m/', null=True, blank=True)

    MANUAL = 'manual'
    RECURRING_AUTO = 'recurring_auto'
    SOURCE_CHOICES = [(MANUAL, 'Manuel'), (RECURRING_AUTO, 'Otomatik (Tekrarlayan)')]
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default=MANUAL, blank=True)

    class Meta:
        ordering = ['-id']

    def __str__(self):
        return f'{self.type} - {self.amount} ({self.date})'


class Loan(models.Model):
    """Vadeli banka borcu: Krediler, KGF. (Revolving krediler Account ile modellenir.)"""
    LOAN = 'loan'
    KGF = 'kgf'
    OTHER = 'other'
    KIND_CHOICES = [(LOAN, 'Kredi'), (KGF, 'KGF'), (OTHER, 'Diğer')]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='loans')
    name = models.CharField(max_length=255)
    kind = models.CharField(max_length=20, choices=KIND_CHOICES, default=LOAN)
    creditor = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='loans')
    bank_name = models.CharField(max_length=255, default='', blank=True)
    principal = models.FloatField(default=0.0)         # ana para
    total_payable = models.FloatField(default=0.0)     # faiz dahil toplam
    paid_amount = models.FloatField(default=0.0)       # ödenen
    interest_rate = models.FloatField(default=0.0)
    term_months = models.IntegerField(default=0)
    start_date = models.CharField(max_length=50, default='', blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f'{self.name} ({self.get_kind_display()})'

    @property
    def remaining(self):
        base = self.total_payable or self.principal or 0
        return max(base - (self.paid_amount or 0), 0)


class Cheque(models.Model):
    """Çek: alınan (müşteri çeki) veya verilen (kendi çekimiz)."""
    RECEIVED = 'received'
    ISSUED = 'issued'
    DIRECTION_CHOICES = [(RECEIVED, 'Alınan'), (ISSUED, 'Verilen')]

    PORTFOLIO = 'portfolio'
    DEPOSITED = 'deposited'
    CASHED = 'cashed'
    GIVEN = 'given'
    BOUNCED = 'bounced'
    STATUS_CHOICES = [
        (PORTFOLIO, 'Portföyde'),
        (DEPOSITED, 'Tahsile Verildi'),
        (CASHED, 'Tahsil Edildi'),
        (GIVEN, 'Ciro/Ödendi'),
        (BOUNCED, 'Karşılıksız'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cheques')
    direction = models.CharField(max_length=10, choices=DIRECTION_CHOICES, default=RECEIVED)
    status = models.CharField(max_length=12, choices=STATUS_CHOICES, default=PORTFOLIO)
    amount = models.FloatField(default=0.0)
    due_date = models.CharField(max_length=50, default='', blank=True)
    bank_name = models.CharField(max_length=255, default='', blank=True)
    serial_no = models.CharField(max_length=100, default='', blank=True)
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='cheques')
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='cheques')

    class Meta:
        ordering = ['due_date']

    def __str__(self):
        return f'{self.get_direction_display()} çek - {self.amount}'


class Sale(models.Model):
    """Satış sözleşmesi: daire / dükkan / arsa satışı."""
    APARTMENT = 'apartment'
    SHOP = 'shop'
    LAND = 'land'
    OTHER = 'other'
    UNIT_CHOICES = [
        (APARTMENT, 'Daire'),
        (SHOP, 'Dükkan'),
        (LAND, 'Arsa'),
        (OTHER, 'Diğer'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sales')
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='sales')
    buyer = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='purchases')
    unit_type = models.CharField(max_length=15, choices=UNIT_CHOICES, default=APARTMENT)
    unit_no = models.CharField(max_length=50, default='', blank=True)
    sale_price = models.FloatField(default=0.0)
    sale_date = models.CharField(max_length=50, default='', blank=True)
    is_completed = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.get_unit_type_display()} {self.unit_no} - {self.sale_price}'

    def collected(self):
        return self.receivables.aggregate(s=Sum('collected_amount'))['s'] or 0

    @property
    def remaining(self):
        return max((self.sale_price or 0) - self.collected(), 0)


class Receivable(models.Model):
    """Alacak / taksit kaydı: daire-dükkan satış taksiti, müşteri/devlet alacağı, hakediş."""
    SALE_INSTALLMENT = 'installment'
    CUSTOMER = 'customer'
    GOVERNMENT = 'government'
    RETENTION = 'retention'  # hakediş/teminat
    OTHER = 'other'
    KIND_CHOICES = [
        (SALE_INSTALLMENT, 'Satış Taksiti'),
        (CUSTOMER, 'Müşteri Alacağı'),
        (GOVERNMENT, 'Devlet Alacağı'),
        (RETENTION, 'Hakediş'),
        (OTHER, 'Diğer'),
    ]

    PENDING = 'pending'
    PARTIAL = 'partial'
    COLLECTED = 'collected'
    OVERDUE = 'overdue'
    STATUS_CHOICES = [
        (PENDING, 'Bekliyor'),
        (PARTIAL, 'Kısmi Tahsil'),
        (COLLECTED, 'Tahsil Edildi'),
        (OVERDUE, 'Gecikmiş'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='receivables')
    kind = models.CharField(max_length=15, choices=KIND_CHOICES, default=CUSTOMER)
    status = models.CharField(max_length=12, choices=STATUS_CHOICES, default=PENDING)
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='receivables')
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='receivables')
    sale = models.ForeignKey(Sale, on_delete=models.CASCADE, null=True, blank=True, related_name='receivables')
    total_amount = models.FloatField(default=0.0)
    collected_amount = models.FloatField(default=0.0)
    due_date = models.CharField(max_length=50, default='', blank=True)
    description = models.CharField(max_length=500, default='', blank=True)

    class Meta:
        ordering = ['due_date']

    def __str__(self):
        return f'{self.get_kind_display()} - {self.remaining}'

    @property
    def remaining(self):
        return max((self.total_amount or 0) - (self.collected_amount or 0), 0)


class RecurringTransaction(models.Model):
    """Tekrarlayan işlem şablonu: vadesi geldiğinde kullanıcı onayıyla gerçek
    bir FinancialTransaction'a dönüştürülür (otomatik oluşturma yok)."""
    WEEKLY = 'weekly'
    MONTHLY = 'monthly'
    INTERVAL_CHOICES = [(WEEKLY, 'Haftalık'), (MONTHLY, 'Aylık')]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recurring_transactions')
    type = models.CharField(max_length=50)  # Gelir, Gider, Tahsilat...
    amount = models.FloatField(default=0.0)
    category = models.CharField(max_length=100, default='', blank=True)
    description = models.CharField(max_length=500, default='', blank=True)
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='recurring_transactions')
    contact = models.ForeignKey(Contact, on_delete=models.SET_NULL, null=True, blank=True, related_name='recurring_transactions')
    from_account = models.ForeignKey(Account, on_delete=models.SET_NULL, null=True, blank=True, related_name='recurring_outgoing')
    to_account = models.ForeignKey(Account, on_delete=models.SET_NULL, null=True, blank=True, related_name='recurring_incoming')
    interval = models.CharField(max_length=10, choices=INTERVAL_CHOICES, default=MONTHLY)
    day_of_month = models.IntegerField(default=1)  # aylık tekrar için (1-28, ay sonu sorunundan kaçınmak için sınırlı)
    next_due_date = models.CharField(max_length=50)  # ISO tarih string'i (uygulamadaki diğer tarih alanlarıyla tutarlı)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['next_due_date']

    def __str__(self):
        return f'{self.description or self.category} ({self.get_interval_display()})'

    def advance_next_due_date(self):
        """next_due_date'i bir periyot ileri alır (onaylandıktan sonra çağrılır)."""
        from datetime import date as _date, timedelta
        d = _date.fromisoformat(self.next_due_date)
        if self.interval == self.WEEKLY:
            d = d + timedelta(days=7)
        else:
            month = d.month + 1 if d.month < 12 else 1
            year = d.year + 1 if d.month == 12 else d.year
            day = min(self.day_of_month or d.day, 28)
            d = _date(year, month, day)
        self.next_due_date = d.isoformat()
        self.save(update_fields=['next_due_date'])

    @classmethod
    def auto_confirm_due(cls, user=None):
        """Vadesi gelmiş (next_due_date <= bugün) aktif şablonları otomatik olarak
        FinancialTransaction'a dönüştürür ve next_due_date'i ilerletir.
        Döner: oluşturulan FinancialTransaction listesi."""
        from datetime import date as _date
        qs = cls.objects.filter(is_active=True, next_due_date__lte=_date.today().isoformat())
        if user is not None:
            qs = qs.filter(user=user)
        created = []
        for template in qs:
            transaction = FinancialTransaction.objects.create(
                user=template.user,
                type=template.type,
                amount=template.amount,
                category=template.category,
                description=template.description,
                project=template.project,
                contact=template.contact,
                from_account=template.from_account,
                to_account=template.to_account,
                date=template.next_due_date,
                source=FinancialTransaction.RECURRING_AUTO,
            )
            template.advance_next_due_date()
            created.append(transaction)
        return created


class Todo(models.Model):
    """Basit yapılacaklar listesi: kişisel ya da bir projeye bağlı."""
    PERSONAL = 'personal'
    PROJECT = 'project'
    SCOPE_CHOICES = [(PERSONAL, 'Kişisel'), (PROJECT, 'Proje')]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='todos')
    title = models.CharField(max_length=255)
    is_done = models.BooleanField(default=False)
    scope = models.CharField(max_length=10, choices=SCOPE_CHOICES, default=PERSONAL)
    project = models.ForeignKey(Project, on_delete=models.CASCADE, null=True, blank=True, related_name='todos')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['is_done', '-created_at']

    def __str__(self):
        return self.title


# ── Hibrit bakiye: işlem değişince ilgili hesapları yeniden hesapla ────────────
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver


@receiver(post_save, sender=FinancialTransaction)
@receiver(post_delete, sender=FinancialTransaction)
def _sync_account_balances(sender, instance, **kwargs):
    for account in (instance.from_account, instance.to_account):
        if account is not None:
            account.recalculate_balance()
