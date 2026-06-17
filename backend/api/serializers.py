from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import (
    User, CompanyProfile, Contact, Category, Account, Project, BudgetLine,
    FinancialTransaction, Loan, Cheque, Sale, Receivable,
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
            'phone1', 'phone2', 'email', 'website', 'base_currency',
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

    class Meta:
        model = Account
        fields = [
            'id', 'name', 'type', 'currency', 'opening_balance', 'balance',
            'credit_limit', 'available_limit', 'bank_logo_painter',
            'account_details', 'is_active',
        ]
        read_only_fields = ['id', 'available_limit']


class ProjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Project
        fields = [
            'id', 'name', 'project_code', 'project_type', 'status', 'status_color_hex', 'status_bg_color_hex',
            'location', 'pafta', 'parsel', 'area_sq_meters', 'total_independent_sections', 'unit_count', 'shop_count',
            'estimated_total_cost', 'estimated_total_revenue', 'currency',
            'image_path', 'start_date', 'end_date', 'description',
        ]
        read_only_fields = ['id']


class BudgetLineSerializer(serializers.ModelSerializer):
    actual_amount = serializers.SerializerMethodField()

    class Meta:
        model = BudgetLine
        fields = ['id', 'project', 'category', 'budgeted_amount', 'currency', 'actual_amount']
        read_only_fields = ['id', 'actual_amount']

    def get_actual_amount(self, obj):
        return obj.actual_amount()


class FinancialTransactionSerializer(serializers.ModelSerializer):
    project_id = serializers.IntegerField(source='project.id', read_only=True, allow_null=True)
    amount_try = serializers.FloatField(read_only=True)

    class Meta:
        model = FinancialTransaction
        fields = [
            'id', 'project_id', 'type', 'amount', 'currency', 'exchange_rate',
            'amount_try', 'date', 'category', 'description',
            'from_account', 'to_account', 'contact',
            'source_name', 'dest_name', 'contact_name', 'document_no', 'due_date',
        ]
        read_only_fields = ['id', 'amount_try']

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
        if not transaction.from_account and not transaction.to_account:
            self._legacy_update_balances(request.user, transaction)

        return transaction

    def _legacy_update_balances(self, user, transaction):
        """source_name/dest_name string'lerinden hesap bularak bakiye günceller (eski akış)."""
        t = transaction
        if t.type == 'Gider' and t.source_name:
            self._adjust(user, t.source_name, -t.amount)
        elif t.type in ('Gelir', 'Tahsilat') and t.source_name:
            self._adjust(user, t.source_name, t.amount)
        elif t.type == 'Transfer':
            if t.source_name:
                self._adjust(user, t.source_name, -t.amount)
            if t.dest_name:
                self._adjust(user, t.dest_name, t.amount)

    def _adjust(self, user, account_name, amount_change):
        try:
            account = Account.objects.get(user=user, name=account_name)
            account.balance += amount_change
            account.save(update_fields=['balance'])
        except Account.DoesNotExist:
            pass


class LoanSerializer(serializers.ModelSerializer):
    remaining = serializers.FloatField(read_only=True)

    class Meta:
        model = Loan
        fields = [
            'id', 'name', 'kind', 'creditor', 'bank_name', 'principal',
            'total_payable', 'paid_amount', 'remaining', 'interest_rate',
            'term_months', 'currency', 'start_date', 'is_active',
        ]
        read_only_fields = ['id', 'remaining']


class ChequeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cheque
        fields = [
            'id', 'direction', 'status', 'amount', 'currency', 'due_date',
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
            'currency', 'sale_date', 'is_completed', 'remaining', 'collected',
        ]
        read_only_fields = ['id', 'remaining', 'collected']

    def get_collected(self, obj):
        return obj.collected()


class ReceivableSerializer(serializers.ModelSerializer):
    remaining = serializers.FloatField(read_only=True)

    class Meta:
        model = Receivable
        fields = [
            'id', 'kind', 'status', 'contact', 'project', 'sale',
            'total_amount', 'collected_amount', 'remaining', 'currency',
            'due_date', 'description',
        ]
        read_only_fields = ['id', 'remaining']
