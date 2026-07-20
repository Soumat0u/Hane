from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import (
    User, CompanyProfile, Contact, Category, Account, Project, BudgetLine,
    FinancialTransaction, Loan, Cheque, Sale, Receivable, RecurringTransaction,
    ProjectDocument, Todo,
)


class RegisterSerializer(serializers.Serializer):
    """Serializer for user registration."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)
    first_name = serializers.CharField(required=False, default='')
    last_name = serializers.CharField(required=False, default='')

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Bu e-posta adresi zaten kayıtlı.')
        return value

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError('Geçersiz e-posta veya şifre.')
        if not user.is_active:
            raise serializers.ValidationError('Bu hesap devre dışı bırakılmış.')
        data['user'] = user
        return data


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'date_joined']
        read_only_fields = ['id', 'email', 'date_joined']


class CompanyProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyProfile
        fields = [
            'id', 'company_name', 'tax_office', 'tax_number',
            'commercial_registry', 'mersis_no', 'address_title',
            'address_line1', 'address_line2', 'city', 'country',
            'phone1', 'phone2', 'email', 'website', 'read_notifications', 'logo',
        ]
        read_only_fields = ['id']


class ContactSerializer(serializers.ModelSerializer):
    balance = serializers.FloatField(read_only=True)

    class Meta:
        model = Contact
        fields = ['id', 'name', 'kind', 'phone', 'email', 'tax_number', 'note', 'balance']
        read_only_fields = ['id', 'balance']


class CategorySerializer(serializers.ModelSerializer):
    child_count = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'type', 'group', 'parent', 'child_count']
        read_only_fields = ['id', 'child_count']

    def get_child_count(self, obj):
        return obj.children.count()

    def validate_parent(self, value):
        # Alt kategori, kullanıcının kendi ana kategorisine bağlanmalı
        request = self.context.get('request')
        if value is not None and request is not None and value.user_id != request.user.id:
            raise serializers.ValidationError('Geçersiz üst kategori.')
        return value


class AccountSerializer(serializers.ModelSerializer):
    available_limit = serializers.FloatField(read_only=True)
    bank_logo_painter = serializers.CharField(required=False, allow_blank=True, default='')
    account_details = serializers.CharField(required=False, allow_blank=True, default='')

    class Meta:
        model = Account
        fields = [
            'id', 'name', 'type', 'opening_balance', 'balance',
            'credit_limit', 'available_limit', 'bank_logo_painter',
            'account_details', 'is_active',
        ]
        read_only_fields = ['id', 'available_limit']

    def create(self, validated_data):
        # `balance` bir ledger cache alanıdır; oluşturma anında hiç işlem yokken
        # doğru değeri (opening_balance) yansıtması için yeniden hesaplanır —
        # aksi halde ilk işleme kadar 0 görünür.
        account = super().create(validated_data)
        account.recalculate_balance()
        return account

    def update(self, instance, validated_data):
        # DİKKAT: recalculate_balance() burada KULLANILMAZ. Legacy işlemler hesaba
        # isim eşleşmesiyle bağlıdır (source_name/dest_name); hesap adı
        # değiştirilirse eski işlemler hâlâ ESKİ adı taşır ve yeniden hesaplama
        # onları hesaba bağlayamaz, birikmiş bakiyeyi sessizce sıfırlar. Bunun
        # yerine sadece opening_balance değiştiyse aradaki fark bakiyeye yansıtılır.
        old_opening = instance.opening_balance
        account = super().update(instance, validated_data)
        if 'opening_balance' in validated_data:
            delta = (account.opening_balance or 0) - (old_opening or 0)
            if delta:
                account.balance = (account.balance or 0) + delta
                account.save(update_fields=['balance'])
        return account


class ProjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Project
        fields = [
            'id', 'name', 'project_code', 'project_type', 'status', 'status_color_hex', 'status_bg_color_hex',
            'location', 'pafta', 'parsel', 'area_sq_meters', 'total_independent_sections', 'unit_count', 'shop_count',
            'estimated_total_cost', 'estimated_total_revenue',
            'image_path', 'start_date', 'end_date', 'description',
        ]
        read_only_fields = ['id']


class BudgetLineSerializer(serializers.ModelSerializer):
    actual_amount = serializers.SerializerMethodField()

    class Meta:
        model = BudgetLine
        fields = ['id', 'project', 'category', 'budgeted_amount', 'actual_amount']
        read_only_fields = ['id', 'actual_amount']

    def get_actual_amount(self, obj):
        return obj.actual_amount()


def _adjust_account_balance(user, account_name, amount_change):
    """İsmiyle bulunan hesabın bakiye cache'ini ``amount_change`` kadar değiştirir."""
    if not account_name:
        return
    try:
        account = Account.objects.get(user=user, name=account_name)
        account.balance += amount_change
        account.save(update_fields=['balance'])
    except Account.DoesNotExist:
        pass


def apply_legacy_balance(user, transaction, sign):
    """FK hesap verilmemiş (isim-bazlı) işlemin bakiye etkisini uygular.

    ``sign=+1`` etkiyi uygular (oluşturma), ``sign=-1`` etkiyi geri alır (silme/düzenleme).
    FK hesaplı işlemlerde bakiye zaten post_save/post_delete sinyaliyle yönetilir.
    """
    t = transaction
    if t.from_account_id or t.to_account_id:
        return
    if t.type == 'Gider':
        account_name = t.source_name or t.dest_name
        _adjust_account_balance(user, account_name, -t.amount * sign)
    elif t.type in ('Gelir', 'Tahsilat', 'Kredi Kullanımı'):
        account_name = t.source_name or t.dest_name
        _adjust_account_balance(user, account_name, t.amount * sign)
    elif t.type == 'Transfer':
        _adjust_account_balance(user, t.source_name, -t.amount * sign)
        _adjust_account_balance(user, t.dest_name, t.amount * sign)


class FinancialTransactionSerializer(serializers.ModelSerializer):
    project_id = serializers.IntegerField(source='project.id', read_only=True, allow_null=True)
    loan = serializers.PrimaryKeyRelatedField(read_only=True)
    cheque = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = FinancialTransaction
        fields = [
            'id', 'project_id', 'type', 'amount',
            'date', 'category', 'description',
            'quantity', 'unit',
            'from_account', 'to_account', 'contact', 'loan', 'cheque',
            'source_name', 'dest_name', 'contact_name', 'document_no', 'due_date',
            'attachment', 'source',
        ]
        read_only_fields = ['id', 'source', 'loan', 'cheque']

    def create(self, validated_data):
        request = self.context.get('request')
        project_id = request.data.get('project_id')

        if project_id:
            try:
                project = Project.objects.get(id=project_id, user=request.user)
                validated_data['project'] = project
            except Project.DoesNotExist:
                pass

        validated_data['user'] = request.user
        transaction = FinancialTransaction.objects.create(**validated_data)

        # FK verilmediyse eski isim-bazlı bakiye güncellemesini uygula (geriye uyum)
        apply_legacy_balance(request.user, transaction, +1)

        return transaction

    def update(self, instance, validated_data):
        request = self.context.get('request')
        user = instance.user
        old_from_account = instance.from_account
        old_to_account = instance.to_account
        # Eski işlemin isim-bazlı bakiye etkisini geri al, güncelle, yeni etkiyi uygula.
        apply_legacy_balance(user, instance, -1)
        instance = super().update(instance, validated_data)

        # `project_id` read_only olduğu için validated_data'ya hiç girmiyor;
        # create()'deki gibi burada da request.data'dan elle işleniyor —
        # aksi halde bir işlemin proje ataması düzenlemede hiç güncellenmiyordu.
        if request is not None and 'project_id' in request.data:
            project_id = request.data.get('project_id')
            if project_id:
                try:
                    instance.project = Project.objects.get(id=project_id, user=user)
                except Project.DoesNotExist:
                    instance.project = None
            else:
                instance.project = None
            instance.save(update_fields=['project'])

        apply_legacy_balance(user, instance, +1)
        # FK hesap değiştiyse ya da kaldırıldıysa eski hesabın bakiyesini de
        # yeniden hesapla — post_save sinyali yalnızca YENİ from_account/to_account'ı
        # günceller, artık bu işlemle ilişkisi kalmayan eski hesabı es geçer.
        # `recalculate_balance()` hem FK'lı hem isim-bazlı işlemleri saydığı için
        # (bkz. Account.recalculate_balance) bu güvenlidir, legacy katkıyı silmez.
        for old_account in (old_from_account, old_to_account):
            if old_account is not None and old_account.id not in (instance.from_account_id, instance.to_account_id):
                old_account.recalculate_balance()
        return instance


class LoanSerializer(serializers.ModelSerializer):
    remaining = serializers.FloatField(read_only=True)

    class Meta:
        model = Loan
        fields = [
            'id', 'name', 'kind', 'creditor', 'bank_name', 'principal',
            'total_payable', 'paid_amount', 'remaining', 'interest_rate',
            'term_months', 'start_date', 'is_active',
        ]
        read_only_fields = ['id', 'remaining']


class ChequeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cheque
        fields = [
            'id', 'direction', 'status', 'amount', 'due_date',
            'bank_name', 'serial_no', 'contact', 'project',
        ]
        read_only_fields = ['id']


class SaleSerializer(serializers.ModelSerializer):
    remaining = serializers.FloatField(read_only=True)
    collected = serializers.SerializerMethodField()

    class Meta:
        model = Sale
        fields = [
            'id', 'project', 'buyer', 'unit_type', 'unit_no', 'sale_price',
            'sale_date', 'down_payment', 'installment_count',
            'is_completed', 'remaining', 'collected',
        ]
        read_only_fields = ['id', 'remaining', 'collected', 'is_completed']

    def get_collected(self, obj):
        return obj.collected()


class ReceivableSerializer(serializers.ModelSerializer):
    remaining = serializers.FloatField(read_only=True)

    class Meta:
        model = Receivable
        fields = [
            'id', 'kind', 'status', 'contact', 'project', 'sale',
            'total_amount', 'collected_amount', 'remaining',
            'due_date', 'description',
        ]
        read_only_fields = ['id', 'remaining']


class RecurringTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecurringTransaction
        fields = [
            'id', 'type', 'amount', 'category', 'description', 'project', 'contact',
            'from_account', 'to_account', 'interval', 'day_of_month', 'next_due_date', 'is_active',
        ]
        read_only_fields = ['id']


class ProjectDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectDocument
        fields = ['id', 'project', 'name', 'file', 'uploaded_at']
        read_only_fields = ['id', 'uploaded_at']


class TodoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Todo
        fields = ['id', 'title', 'is_done', 'scope', 'project', 'created_at']
        read_only_fields = ['id', 'created_at']
