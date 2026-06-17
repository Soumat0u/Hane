from rest_framework import viewsets, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

from .models import (
    User, CompanyProfile, Contact, Category, Account, Project, BudgetLine,
    FinancialTransaction, Loan, Cheque, Sale, Receivable,
)
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    CompanyProfileSerializer, ContactSerializer, CategorySerializer,
    AccountSerializer, ProjectSerializer, BudgetLineSerializer,
    FinancialTransactionSerializer, LoanSerializer, ChequeSerializer,
    SaleSerializer, ReceivableSerializer,
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

@api_view(['GET', 'PUT'])
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


class ChequeViewSet(_UserOwnedViewSet):
    model = Cheque
    serializer_class = ChequeSerializer


class SaleViewSet(_UserOwnedViewSet):
    model = Sale
    serializer_class = SaleSerializer


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
