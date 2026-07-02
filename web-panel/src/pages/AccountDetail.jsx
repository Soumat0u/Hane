import { useMemo } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, ArrowUpRight, ArrowDownLeft, ArrowLeftRight, History } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'

const fmtDate = (raw) => {
  if (!raw) return '-'
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

/** Bir işlemin bu hesaba göre gelir mi gider mi olduğunu belirler (mobil `kasa_detay_view` ile aynı mantık). */
function resolveIsIncome(t, accountName) {
  if (t.type === 'Transfer') {
    if (t.dest_name === accountName) return true
    if (t.source_name === accountName) return false
  }
  if (t.type === 'Gelir' || t.type === 'Tahsilat' || t.type === 'Satış' || t.type === 'Borçlanma' || t.type === 'Sermaye' || t.type === 'Kredi Kullanımı') {
    return true
  }
  return false
}

export default function AccountDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { accounts, transactions, projects, loading, loaded } = useData()

  const account = useMemo(
    () => accounts.find((a) => String(a.id) === String(id)) || null,
    [accounts, id],
  )

  const relatedTx = useMemo(() => {
    if (!account) return []
    const list = transactions.filter((t) => t.source_name === account.name || t.dest_name === account.name)
    return [...list].sort((a, b) => new Date(b.date) - new Date(a.date))
  }, [transactions, account])

  const projectNames = useMemo(() => {
    const m = {}
    projects.forEach((p) => { if (p.id != null) m[p.id] = p.name })
    return m
  }, [projects])

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  if (!account) {
    return (
      <div>
        <button className="btn-inline-text" onClick={() => navigate(-1)} style={{ marginBottom: '1rem' }}>
          <ArrowLeft size={16} /> Geri
        </button>
        <div className="summary-box">
          <div className="empty-state">
            <span className="text-danger" style={{ fontWeight: 700 }}>Hesap bulunamadı.</span>
          </div>
        </div>
      </div>
    )
  }

  const isCard = account.type === 'Kredi Kartı'

  return (
    <div>
      <div className="detail-topbar">
        <button className="icon-btn" onClick={() => navigate(-1)} title="Geri">
          <ArrowLeft size={20} />
        </button>
        <h1 className="detail-title">{account.name}</h1>
      </div>

      {/* Bakiye / Limit kartı */}
      <div className="summary-box" style={{ padding: '1.5rem', marginBottom: '1.5rem' }}>
        {isCard ? (
          <div style={{ display: 'flex', justifyContent: 'space-evenly', textAlign: 'center' }}>
            <div>
              <div className="summary-label" style={{ marginBottom: '0.5rem' }}>KULLANILABİLİR LİMİT</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--color-primary)' }}>
                {formatCurrency(account.available_limit)}
              </div>
            </div>
            <div style={{ width: 1, background: 'var(--color-border)' }} />
            <div>
              <div className="summary-label" style={{ marginBottom: '0.5rem' }}>GÜNCEL BORÇ</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--color-danger)' }}>
                {formatCurrency(Math.abs(num(account.balance)))}
              </div>
            </div>
          </div>
        ) : (
          <div style={{ textAlign: 'center' }}>
            <div className="summary-label" style={{ marginBottom: '0.5rem' }}>GÜNCEL BAKİYE</div>
            <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--color-primary)' }}>
              {formatCurrency(account.balance)}
            </div>
          </div>
        )}
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: '1rem' }}>
          <span className="status-badge-inline" style={{ color: 'var(--color-accent)', backgroundColor: 'var(--color-accentBg)' }}>
            {account.type}
          </span>
        </div>
      </div>

      <div className="section-header" style={{ marginTop: 0 }}>
        <span className="section-title">HESAP HAREKETLERİ</span>
        <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--color-text-muted)' }}>{relatedTx.length} İşlem</span>
      </div>

      {relatedTx.length === 0 ? (
        <div className="empty-state" style={{ padding: '4rem 0' }}>
          <History size={44} />
          <span style={{ fontWeight: 600 }}>Henüz hesap hareketi bulunmuyor.</span>
        </div>
      ) : (
        <div className="list-group">
          {relatedTx.map((t) => {
            const isIncome = resolveIsIncome(t, account.name)
            const isTransfer = t.type === 'Transfer'
            const Icon = isTransfer ? ArrowLeftRight : (isIncome ? ArrowDownLeft : ArrowUpRight)
            const color = isTransfer ? 'var(--color-accent)' : (isIncome ? 'var(--color-success)' : 'var(--color-danger)')

            let counterparty = isIncome ? t.source_name : t.dest_name
            if (!counterparty && t.project_id != null) counterparty = projectNames[t.project_id] || `Proje ${t.project_id}`
            if (!counterparty) counterparty = 'Bilinmeyen'

            return (
              <div
                className="list-item"
                key={t.id}
                onClick={() => navigate(`/dashboard/transactions/${t.id}`)}
                style={{ cursor: 'pointer' }}
              >
                <div className="list-icon-box" style={{ background: `color-mix(in srgb, ${color} 15%, transparent)`, color }}>
                  <Icon size={20} />
                </div>
                <div className="list-item-content">
                  <div className="list-item-title">{t.description || t.category || t.type}</div>
                  <div className="list-item-subtitle">{fmtDate(t.date)} • {counterparty}</div>
                </div>
                <div className="list-item-value" style={{ color }}>
                  {isTransfer ? '' : (isIncome ? '+' : '-')}{formatCurrency(t.amount)}
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
