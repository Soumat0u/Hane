from rest_framework.test import APITestCase
from rest_framework.authtoken.models import Token

from .models import User, Account, Project, Contact, Loan


class CrossUserRelationTests(APITestCase):
    """Bir kullanıcı, başka bir kullanıcının hesap/proje/carisine bağlı kayıt oluşturamamalı."""

    def setUp(self):
        self.owner = User.objects.create_user(email='owner@example.com', password='Owner-pass-123')
        self.attacker = User.objects.create_user(email='attacker@example.com', password='Attacker-pass-123')
        self.account = Account.objects.create(user=self.owner, name='Ana Hesap', type='Banka', opening_balance=1000)
        self.account.recalculate_balance()
        self.project = Project.objects.create(
            user=self.owner, name='Proje', status='Planlama', status_color_hex='#000', status_bg_color_hex='#fff',
            location='Ankara',
        )
        self.contact = Contact.objects.create(user=self.owner, name='Cari')
        token = Token.objects.create(user=self.attacker)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    def _owner_balance(self):
        self.account.refresh_from_db()
        return self.account.balance

    def test_transaction_cannot_target_foreign_account(self):
        for field in ('to_account', 'from_account'):
            res = self.client.post('/api/transactions/', {
                'type': 'Gelir', 'amount': 500, 'date': '2026-10-01', 'category': 'x', field: self.account.id,
            }, format='json')
            self.assertEqual(res.status_code, 400, field)
            self.assertIn(field, res.data)
        self.assertEqual(self._owner_balance(), 1000)

    def test_transaction_cannot_target_foreign_contact(self):
        res = self.client.post('/api/transactions/', {
            'type': 'Gider', 'amount': 1, 'date': '2026-10-01', 'category': 'x', 'contact': self.contact.id,
        }, format='json')
        self.assertEqual(res.status_code, 400)

    def test_receivable_and_budget_cannot_target_foreign_project(self):
        res = self.client.post('/api/receivables/', {
            'kind': 'customer', 'total_amount': 1, 'description': 'x', 'project': self.project.id,
        }, format='json')
        self.assertEqual(res.status_code, 400)
        res = self.client.post('/api/budget-lines/', {
            'project': self.project.id, 'category': 'x', 'budgeted_amount': 1,
        }, format='json')
        self.assertEqual(res.status_code, 400)

    def test_loan_payment_cannot_use_foreign_account(self):
        loan = Loan.objects.create(user=self.attacker, name='Kredi', principal=100, total_payable=100)
        res = self.client.post(f'/api/loans/{loan.id}/pay/', {
            'amount': 50, 'from_account': self.account.id,
        }, format='json')
        self.assertEqual(res.status_code, 400)
        self.assertEqual(self._owner_balance(), 1000)

    def test_own_relations_still_work(self):
        own = Account.objects.create(user=self.attacker, name='Kendi Hesabım', type='Banka', opening_balance=0)
        res = self.client.post('/api/transactions/', {
            'type': 'Gelir', 'amount': 250, 'date': '2026-10-01', 'category': 'x', 'to_account': own.id,
        }, format='json')
        self.assertEqual(res.status_code, 201)
        own.refresh_from_db()
        self.assertEqual(own.balance, 250)


class SaleDownPaymentTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='seller@example.com', password='Seller-pass-123')
        self.account = Account.objects.create(user=self.user, name='Ana Hesap', type='Banka', opening_balance=0)
        self.account.recalculate_balance()
        self.project = Project.objects.create(
            user=self.user, name='Proje', status='Planlama', status_color_hex='#000', status_bg_color_hex='#fff',
            location='Ankara',
        )
        token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    def _sell(self, **extra):
        payload = {
            'project': self.project.id, 'unit_type': 'apartment', 'unit_no': 'A-5',
            'sale_price': 1000000, 'sale_date': '2026-10-01', 'down_payment': 200000,
        }
        payload.update(extra)
        return self.client.post('/api/sales/', payload, format='json')

    def test_down_payment_goes_to_account_and_counts_as_collected(self):
        res = self._sell(down_payment_account=self.account.id)
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['collected'], 200000)
        self.assertEqual(res.data['remaining'], 800000)
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 200000)
        receivables = self.client.get('/api/receivables/').data
        self.assertEqual(sum(r['total_amount'] for r in receivables), 800000)
        tx = self.client.get('/api/transactions/').data
        self.assertEqual([(t['type'], t['amount'], t['to_account'], t['project_id']) for t in tx],
                         [('Tahsilat', 200000, self.account.id, self.project.id)])

    def test_without_account_down_payment_is_not_booked(self):
        res = self._sell()
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data['remaining'], 800000)
        self.assertEqual(self.client.get('/api/transactions/').data, [])

    def test_foreign_down_payment_account_rejected(self):
        other = User.objects.create_user(email='x@example.com', password='Other-pass-123')
        foreign = Account.objects.create(user=other, name='X', type='Banka', opening_balance=0)
        res = self._sell(down_payment_account=foreign.id)
        self.assertEqual(res.status_code, 400)
        self.assertEqual(self.client.get('/api/sales/').data, [])
