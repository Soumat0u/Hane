import calendar
from datetime import datetime

from django.db import transaction as db_transaction
from django.utils import timezone
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

from .models import (
    User, CompanyProfile, Contact, Category, Account, Project, BudgetLine,
    FinancialTransaction, Loan, Cheque, Sale, Receivable, RecurringTransaction,
    ProjectDocument, Todo,
)
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    CompanyProfileSerializer, ContactSerializer, CategorySerializer,
    AccountSerializer, ProjectSerializer, BudgetLineSerializer,
    FinancialTransactionSerializer, LoanSerializer, ChequeSerializer,
    SaleSerializer, ReceivableSerializer, RecurringTransactionSerializer, apply_legacy_balance,
    ProjectDocumentSerializer, TodoSerializer,
)


# ── Auth Views ──────────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_view(request):
    """Register a new user with email and password."""
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    token, _ = Token.objects.get_or_create(user=user)

    # Create empty company profile for the new user
    CompanyProfile.objects.get_or_create(user=user)

    # Yeni kullanıcıya varsayılan gelir/gider kategorilerini yükle
    from .default_categories import seed_categories_for_user
    seed_categories_for_user(user)

    return Response({
        'token': token.key,
        'user': UserSerializer(user).data,
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login_view(request):
    """Login with email and password, returns auth token."""
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.validated_data['user']
    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data,
    })


@api_view(['POST'])
def logout_view(request):
    """Logout - delete user's auth token."""
    request.user.auth_token.delete()
    return Response({'detail': 'Çıkış yapıldı.'}, status=status.HTTP_200_OK)


@api_view(['GET'])
def me_view(request):
    """Get current authenticated user info."""
    return Response(UserSerializer(request.user).data)


# ── Company Profile ─────────────────────────────────────────────────────────

@api_view(['GET', 'PUT', 'PATCH'])
def company_profile_view(request):
    """Get or update the company profile for the authenticated user."""
    profile, _ = CompanyProfile.objects.get_or_create(user=request.user)

    if request.method == 'GET':
        return Response(CompanyProfileSerializer(profile).data)

    serializer = CompanyProfileSerializer(profile, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


# ── ViewSets ────────────────────────────────────────────────────────────────

class AccountViewSet(viewsets.ModelViewSet):
    serializer_class = AccountSerializer

    def get_queryset(self):
        return Account.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ProjectViewSet(viewsets.ModelViewSet):
    serializer_class = ProjectSerializer

    def get_queryset(self):
        return Project.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TransactionViewSet(viewsets.ModelViewSet):
    serializer_class = FinancialTransactionSerializer

    def get_queryset(self):
        qs = FinancialTransaction.objects.filter(user=self.request.user)
        project_id = self.request.query_params.get('project_id')
        if project_id:
            qs = qs.filter(project_id=project_id)
        return qs

    def perform_create(self, serializer):
        # create is handled in serializer.create() which sets user and handles balances
        serializer.save()

    def perform_destroy(self, instance):
        # İsim-bazlı işlemin bakiye etkisini geri al (FK hesaplı olanları sinyal yönetir).
        apply_legacy_balance(instance.user, instance, -1)
        instance.delete()


# ── Yeni model ViewSet'leri ───────────────────────────────────────────────────

class _UserOwnedViewSet(viewsets.ModelViewSet):
    """Kullanıcıya ait kayıtları filtreleyen ve oluştururken user atayan taban sınıf."""
    model = None

    def get_queryset(self):
        return self.model.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ContactViewSet(_UserOwnedViewSet):
    model = Contact
    serializer_class = ContactSerializer


class CategoryViewSet(_UserOwnedViewSet):
    model = Category
    serializer_class = CategorySerializer

    def get_queryset(self):
        qs = Category.objects.filter(user=self.request.user)
        # ?type=cost|income, ?parent=<id>, ?main=1 (sadece ana kategoriler)
        ctype = self.request.query_params.get('type')
        if ctype:
            qs = qs.filter(type=ctype)
        parent_id = self.request.query_params.get('parent')
        if parent_id:
            qs = qs.filter(parent_id=parent_id)
        elif self.request.query_params.get('main') == '1':
            qs = qs.filter(parent__isnull=True)
        return qs


class LoanViewSet(_UserOwnedViewSet):
    model = Loan
    serializer_class = LoanSerializer

    @action(detail=True, methods=['post'])
    def pay(self, request, pk=None):
        """Krediye ödeme işler: paid_amount artışı ve karşılık gelen hesap çıkışı
        tek bir atomik işlemde yapılır (istemcinin iki ayrı isteği sırasında
        oluşabilecek tutarsızlığı önler)."""
        loan = self.get_object()
        amount = float(request.data.get('amount') or 0)
        if amount <= 0:
            return Response({'detail': 'Geçersiz tutar.'}, status=status.HTTP_400_BAD_REQUEST)
        from_account_id = request.data.get('from_account')
        date = request.data.get('date') or None
        with db_transaction.atomic():
            loan.paid_amount = (loan.paid_amount or 0) + amount
            loan.save(update_fields=['paid_amount'])
            transaction = FinancialTransaction.objects.create(
                user=request.user,
                type='Gider',
                amount=amount,
                date=date or timezone.now().date().isoformat(),
                category='Kredi Ödemesi',
                description=f'{loan.name} kredi ödemesi',
                from_account_id=from_account_id,
                loan=loan,
            )
        return Response({
            'loan': LoanSerializer(loan).data,
            'transaction': FinancialTransactionSerializer(transaction).data,
        }, status=status.HTTP_200_OK)


class ChequeViewSet(_UserOwnedViewSet):
    model = Cheque
    serializer_class = ChequeSerializer

    @action(detail=True, methods=['post'])
    def pay(self, request, pk=None):
        """Verilen çeki öder: status='given' ve karşılık gelen hesap çıkışı
        tek bir atomik işlemde yapılır."""
        cheque = self.get_object()
        amount = float(request.data.get('amount') or cheque.amount or 0)
        if amount <= 0:
            return Response({'detail': 'Geçersiz tutar.'}, status=status.HTTP_400_BAD_REQUEST)
        from_account_id = request.data.get('from_account')
        date = request.data.get('date') or None
        with db_transaction.atomic():
            cheque.status = Cheque.GIVEN
            cheque.save(update_fields=['status'])
            transaction = FinancialTransaction.objects.create(
                user=request.user,
                type='Gider',
                amount=amount,
                date=date or timezone.now().date().isoformat(),
                category='Çek Ödemesi',
                description=f'{cheque.bank_name} çeki ödemesi' if cheque.bank_name else 'Çek ödemesi',
                from_account_id=from_account_id,
                cheque=cheque,
            )
        return Response({
            'cheque': ChequeSerializer(cheque).data,
            'transaction': FinancialTransactionSerializer(transaction).data,
        }, status=status.HTTP_200_OK)


def _add_months(base_date, months):
    month = base_date.month - 1 + months
    year = base_date.year + month // 12
    month = month % 12 + 1
    day = min(base_date.day, calendar.monthrange(year, month)[1])
    return base_date.replace(year=year, month=month, day=day)


class SaleViewSet(_UserOwnedViewSet):
    model = Sale
    serializer_class = SaleSerializer

    def create(self, request, *args, **kwargs):
        """Satışı ve varsa taksit/vade planını (Receivable satırları) tek atomik
        istekte oluşturur. Önceden istemci iki ayrı istek atıyordu (satış + alacak)
        ve oluşan alacağı hiçbir zaman `sale` FK'sıyla satışa bağlamıyordu — bu da
        Sale.collected()/remaining'in her zaman yanlış (sıfır tahsilat) görünmesine
        yol açıyordu. Artık sunucu tarafında, tek seferde ve doğru bağlantıyla yapılır.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        with db_transaction.atomic():
            sale = serializer.save(user=request.user)
            self._generate_installments(sale, request.data)
        sale.refresh_from_db()
        return Response(self.get_serializer(sale).data, status=status.HTTP_201_CREATED)

    def _generate_installments(self, sale, data):
        create_receivable = data.get('create_receivable', True)
        if isinstance(create_receivable, str):
            create_receivable = create_receivable.lower() not in ('false', '0', '')
        if not create_receivable:
            return
        down_payment = max(float(data.get('down_payment') or 0), 0)
        installment_count = int(data.get('installment_count') or 0)
        first_due_date = data.get('first_due_date') or sale.sale_date
        remaining = max((sale.sale_price or 0) - down_payment, 0)
        if remaining <= 0:
            return

        unit_label = f'{sale.get_unit_type_display()} {sale.unit_no}'.strip()

        if installment_count <= 0:
            Receivable.objects.create(
                user=sale.user, kind=Receivable.SALE_INSTALLMENT, status=Receivable.PENDING,
                contact=sale.buyer, project=sale.project, sale=sale,
                total_amount=remaining, due_date=first_due_date,
                description=f'{unit_label} satış bedeli'.strip(),
            )
            return

        try:
            base_date = datetime.strptime(first_due_date, '%Y-%m-%d').date()
        except (ValueError, TypeError):
            base_date = timezone.now().date()

        per_installment = round(remaining / installment_count, 2)
        allocated = 0.0
        for i in range(installment_count):
            amount = per_installment if i < installment_count - 1 else round(remaining - allocated, 2)
            due = _add_months(base_date, i)
            Receivable.objects.create(
                user=sale.user, kind=Receivable.SALE_INSTALLMENT, status=Receivable.PENDING,
                contact=sale.buyer, project=sale.project, sale=sale,
                total_amount=amount, due_date=due.isoformat(),
                description=f'{unit_label} - {i + 1}. Taksit'.strip(),
            )
            allocated += amount


class ReceivableViewSet(_UserOwnedViewSet):
    model = Receivable
    serializer_class = ReceivableSerializer


class BudgetLineViewSet(viewsets.ModelViewSet):
    """Bütçe kalemleri projeye bağlı; kullanıcının projeleri üzerinden filtrelenir."""
    serializer_class = BudgetLineSerializer

    def get_queryset(self):
        qs = BudgetLine.objects.filter(project__user=self.request.user)
        project_id = self.request.query_params.get('project_id')
        if project_id:
            qs = qs.filter(project_id=project_id)
        return qs


class RecurringTransactionViewSet(_UserOwnedViewSet):
    model = RecurringTransaction
    serializer_class = RecurringTransactionSerializer

    def get_queryset(self):
        RecurringTransaction.auto_confirm_due(user=self.request.user)
        return super().get_queryset()

    @action(detail=True, methods=['post'])
    def confirm(self, request, pk=None):
        """Şablonu onayla: gerçek bir FinancialTransaction oluştur, next_due_date'i ilerlet."""
        template = self.get_object()
        transaction = FinancialTransaction.objects.create(
            user=request.user,
            type=template.type,
            amount=template.amount,
            category=template.category,
            description=template.description,
            project=template.project,
            contact=template.contact,
            from_account=template.from_account,
            to_account=template.to_account,
            date=request.data.get('date') or template.next_due_date,
        )
        template.advance_next_due_date()
        return Response(FinancialTransactionSerializer(transaction).data, status=status.HTTP_201_CREATED)


class ProjectDocumentViewSet(_UserOwnedViewSet):
    model = ProjectDocument
    serializer_class = ProjectDocumentSerializer

    def get_queryset(self):
        qs = ProjectDocument.objects.filter(user=self.request.user)
        project_id = self.request.query_params.get('project_id')
        if project_id:
            qs = qs.filter(project_id=project_id)
        return qs


class TodoViewSet(_UserOwnedViewSet):
    model = Todo
    serializer_class = TodoSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
        # Sadece son 10 görevi tutacağız, yeni eklendikçe eskiler silinecek
        todos_qs = Todo.objects.filter(user=self.request.user).order_by('-created_at')
        if todos_qs.count() > 10:
            keep_ids = list(todos_qs.values_list('id', flat=True)[:10])
            Todo.objects.filter(user=self.request.user).exclude(id__in=keep_ids).delete()

