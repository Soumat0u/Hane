import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, Wallet, Banknote, ArrowRight } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'

function AccountGroup({ title, accounts, iconClass, onItemClick }) {
  return (
    <div>
      <div className="section-header">
        <span className="section-title">{title}</span>
        <button className="btn-inline-text" disabled>
          <Plus size={16} /> Yeni İşlem
        </button>
      </div>
      {accounts.length === 0 ? (
        <div className="summary-box">
          <div className="empty-state" style={{ padding: '1.5rem 0' }}>
            <span>Kayıt bulunamadı.</span>
          </div>
        </div>
      ) : (
        <div className="list-group">
          {accounts.map((a) => (
            <div className="list-item" key={a.id} onClick={() => onItemClick(a)} style={{ cursor: 'pointer' }}>
              <div className="list-icon-box">
                <Banknote size={20} className={iconClass} />
              </div>
              <div className="list-item-content">
                <div className="list-item-title">{a.name}</div>
              </div>
              <div className="list-item-value-box">
                <div className="list-item-value">{formatCurrency(a.balance)}</div>
              </div>
              <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default function Accounts() {
  const navigate = useNavigate()
  const { accounts, loading, loaded, error } = useData()

  const bankAccounts = useMemo(() => accounts.filter((a) => a.type === 'Banka'), [accounts])
  const cashAccounts = useMemo(() => accounts.filter((a) => a.type === 'Nakit'), [accounts])

  const totalBankalar = useMemo(() => bankAccounts.reduce((s, a) => s + num(a.balance), 0), [bankAccounts])
  const totalNakit = useMemo(() => cashAccounts.reduce((s, a) => s + num(a.balance), 0), [cashAccounts])
  // Mobildeki `getTotalBalance()` ile aynı: TÜM hesapların (kredi kartı dahil) bakiye toplamı.
  const kasaTotal = useMemo(() => accounts.reduce((s, a) => s + num(a.balance), 0), [accounts])

  const goToAccount = (account) => navigate(`/dashboard/accounts/${account.id}`)

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  if (error && !loaded) {
    return (
      <div className="summary-box">
        <div className="empty-state">
          <span className="text-danger" style={{ fontWeight: 700 }}>{error}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="page-header-banner total-card-green" style={{ background: 'var(--banner-accounts)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>TOPLAM KASA</div>
          <div className="total-card-value" style={{ color: 'var(--banner-text)' }}>{formatCurrency(kasaTotal)}</div>
        </div>
        <div className="total-card-icon">
          <Wallet size={36} color="var(--banner-text)" />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', alignItems: 'start' }}>

        {/* SOL SÜTUN: Bankalar & Nakit */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <AccountGroup title="BANKALAR" accounts={bankAccounts} iconClass="text-info" onItemClick={goToAccount} />
          <AccountGroup title="NAKİT" accounts={cashAccounts} iconClass="text-success" onItemClick={goToAccount} />
        </div>

        {/* SAĞ SÜTUN: Özet */}
        <div>
          <div className="section-header">
            <span className="section-title">ÖZET</span>
          </div>
          <div className="summary-box">
            <div className="summary-row">
              <span className="summary-label">Toplam Bankalar</span>
              <span className="summary-value">{formatCurrency(totalBankalar)}</span>
            </div>
            <div className="summary-row">
              <span className="summary-label">Nakit</span>
              <span className="summary-value">{formatCurrency(totalNakit)}</span>
            </div>
            <div className="summary-total-row">
              <span className="summary-total-label" style={{ color: 'var(--color-primary)' }}>TOPLAM KASA</span>
              <span className="summary-total-value" style={{ color: 'var(--color-primary)' }}>{formatCurrency(kasaTotal)}</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  )
}
