from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'accounts', views.AccountViewSet, basename='account')
router.register(r'projects', views.ProjectViewSet, basename='project')
router.register(r'transactions', views.TransactionViewSet, basename='transaction')
router.register(r'contacts', views.ContactViewSet, basename='contact')
router.register(r'categories', views.CategoryViewSet, basename='category')
router.register(r'loans', views.LoanViewSet, basename='loan')
router.register(r'cheques', views.ChequeViewSet, basename='cheque')
router.register(r'sales', views.SaleViewSet, basename='sale')
router.register(r'receivables', views.ReceivableViewSet, basename='receivable')
router.register(r'budget-lines', views.BudgetLineViewSet, basename='budgetline')

urlpatterns = [
    # Auth
    path('auth/register/', views.register_view, name='register'),
    path('auth/login/', views.login_view, name='login'),
    path('auth/logout/', views.logout_view, name='logout'),
    path('auth/me/', views.me_view, name='me'),

    # Company Profile (singleton per user)
    path('company-profile/', views.company_profile_view, name='company-profile'),

    # CRUD via router
    path('', include(router.urls)),
]
