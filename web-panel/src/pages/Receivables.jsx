import { useMemo, useState } from 'react'
import { ArrowDownToLine, Plus, X, Banknote, ChevronRight } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num, parseMoneyInput, formatAmountForDisplay } from '../utils'
import MoneyInput from '../components/MoneyInput'

const KIND_LABELS = {
  installment: 'Satış Taksiti',
  customer: 'Müşteri Alacağı',
  government: 'Devlet Alacağı',
  retention: 'Hakediş',
  other: 'Diğer',
}

const fmtDate = (raw) => {
  if (!raw) return null
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function CollectModal({ receivable, accounts, onClose, onCollect }) {
  const remaining = num(receivable.total_amount) - num(receivable.collected_amount)
  const [amount, setAmount] = useState(remaining > 0 ? formatAmountForDisplay(remaining) : '')
  const [accountId, setAccountId] = useState(accounts[0]?.id || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (parseMoneyInput(amount) <= 0) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onCollect({ receivable, amount: parseMoneyInput(amount), toAccountId: accountId ? Number(accountId) : null })
      onClose()
    } catch {
      setErr('Tahsilat kaydedilemedi. Lütfen tekrar deneyin.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">Tahsilat</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div style={{ marginBottom: '1rem', color: 'var(--color-text-muted)', fontSize: '0.9rem' }}>
              Kalan: <strong>{formatCurrency(remaining)}</strong>
            </div>
            <div className="form-group">
              <label className="form-label">Tahsil Edilen Tutar (₺)</label>
              <MoneyInput value={amount} onChange={setAmount} autoFocus />
            </div>
            <div className="form-group">
              <label className="form-label">Hesap</label>
              {accounts.length === 0 ? (
                <div className="error-message">Önce bir Banka/Nakit hesabı ekleyin.</div>
              ) : (
                <select className="form-input" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                  {accounts.map((a) => (
                    <option key={a.id} value={a.id}>{a.name} hesabına</option>
                  ))}
                </select>
              )}
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose} disabled={saving}>Vazgeç</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving || accounts.length === 0}>
              {saving ? <span className="loader" /> : 'Tahsil Et'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function NewReceivableModal({ projects, onClose, onSave }) {
  const [kind, setKind] = useState('customer')
  const [description, setDescription] = useState('')
  const [totalAmount, setTotalAmount] = useState('')
  const [projectId, setProjectId] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!description.trim()) {
      setErr('Açıklama zorunludur.')
      return
    }
    if (parseMoneyInput(totalAmount) <= 0) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onSave({
        kind,
        status: 'pending',
        description: description.trim(),
        total_amount: parseMoneyInput(totalAmount),
        collected_amount: 0,
        project: projectId ? Number(projectId) : null,
        due_date: dueDate,
      })
      onClose()
    } catch {
      setErr('Kayıt başarısız oldu. Lütfen tekrar deneyin.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">Yeni Alacak</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Tür</label>
              <select className="form-input" value={kind} onChange={(e) => setKind(e.target.value)}>
                {Object.entries(KIND_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Açıklama</label>
              <input className="form-input" type="text" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Örn. A Blok 3. taksit" />
            </div>
            <div className="form-group">
              <label className="form-label">Toplam Tutar (₺)</label>
              <MoneyInput value={totalAmount} onChange={setTotalAmount} />
            </div>
            {projects.length > 0 && (
              <div className="form-group">
                <label className="form-label">Proje (opsiyonel)</label>
                <select className="form-input" value={projectId} onChange={(e) => setProjectId(e.target.value)}>
                  <option value="">Genel (proje yok)</option>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </div>
            )}
            <div className="form-group">
              <label className="form-label">Vade Tarihi</label>
              <input className="form-input" type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose} disabled={saving}>İptal</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving}>
              {saving ? <span className="loader" /> : 'Kaydet'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default function Receivables() {
  const { receivables, accounts, projects, cheques, addReceivable, collectReceivable, loading, loaded } = useData()
  const [collectTarget, setCollectTarget] = useState(null)
  const [newModalOpen, setNewModalOpen] = useState(false)

  const openReceivables = useMemo(
    () => receivables.filter((r) => num(r.total_amount) - num(r.collected_amount) > 0),
    [receivables],
  )

  // Toplam alacak, mobil `FinanceProvider.getTotalAlacak()` ile aynı mantıkla
  // henüz tahsil edilmemiş (kasaya girmemiş) alınan çekleri de içerir.
  const alinanCekler = useMemo(
    () => (cheques || []).filter((c) => c.direction === 'received' && c.status !== 'cashed').reduce((s, c) => s + num(c.amount), 0),
    [cheques],
  )

  const total = useMemo(
    () => openReceivables.reduce((s, r) => s + (num(r.total_amount) - num(r.collected_amount)), 0) + alinanCekler,
    [openReceivables, alinanCekler],
  )

  const collectableAccounts = useMemo(
    () => accounts.filter((a) => a.type === 'Banka' || a.type === 'Nakit'),
    [accounts],
  )

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  return (
    <div>
      <div className="page-header-banner total-card-green" style={{ background: 'var(--banner-receivables)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>TOPLAM ALACAK</div>
          <div className="total-card-value" style={{ color: 'var(--banner-text)' }}>{formatCurrency(total)}</div>
        </div>
        <div className="total-card-icon">
          <ArrowDownToLine size={36} color="var(--banner-text)" />
        </div>
      </div>

      <div className="section-header" style={{ marginTop: '1.75rem' }}>
        <span className="section-title">AÇIK ALACAKLAR</span>
        <button className="btn-inline-text" onClick={() => setNewModalOpen(true)}>
          <Plus size={16} /> Yeni Alacak
        </button>
      </div>

      <div className="list-group">
        {openReceivables.length === 0 ? (
          <div className="debt-empty">Açık alacak yok.</div>
        ) : (
          openReceivables.map((r) => {
            const remaining = num(r.total_amount) - num(r.collected_amount)
            const due = fmtDate(r.due_date)
            const overdue = r.due_date && new Date(r.due_date) < new Date(new Date().setHours(0, 0, 0, 0))
            return (
              <div className="list-item" key={r.id}>
                <div className="list-icon-box"><Banknote size={20} className="text-primary" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">{r.description || KIND_LABELS[r.kind] || 'Alacak'}</div>
                  {due && (
                    <div className="list-item-subtitle" style={{ color: overdue ? 'var(--color-danger)' : undefined, fontWeight: 600 }}>
                      {due}
                    </div>
                  )}
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div className="list-item-value">{formatCurrency(remaining)}</div>
                  <button className="btn-inline-text" style={{ fontSize: '0.8rem' }} onClick={() => setCollectTarget(r)}>
                    Tahsil Et
                  </button>
                </div>
                <ChevronRight size={14} className="text-muted" style={{ marginLeft: '0.75rem' }} />
              </div>
            )
          })
        )}
      </div>

      {collectTarget && (
        <CollectModal
          receivable={collectTarget}
          accounts={collectableAccounts}
          onClose={() => setCollectTarget(null)}
          onCollect={collectReceivable}
        />
      )}

      {newModalOpen && (
        <NewReceivableModal
          projects={projects}
          onClose={() => setNewModalOpen(false)}
          onSave={addReceivable}
        />
      )}
    </div>
  )
}
