import { useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { Repeat, Plus, X, Trash2 } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'

const TYPE_LABELS = { Gider: 'Gider', Gelir: 'Gelir', Tahsilat: 'Tahsilat' }
const INTERVAL_LABELS = { monthly: 'Aylık', weekly: 'Haftalık' }

function DeleteRecurringModal({ target, onClose, onConfirm }) {
  const [deleting, setDeleting] = useState(false)
  const [err, setErr] = useState('')
  const handleDelete = async () => {
    setDeleting(true)
    setErr('')
    try {
      await onConfirm(target.id)
    } catch {
      setErr('Silinemedi. Lütfen tekrar deneyin.')
      setDeleting(false)
    }
  }
  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 340 }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header" style={{ padding: '1rem 1.25rem' }}>
          <span className="modal-title">Şablonu Sil</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={18} /></button>
        </div>
        <div className="modal-body" style={{ padding: '0.25rem 1.25rem 1.1rem' }}>
          {err && <div className="error-message">{err}</div>}
          <p style={{ color: 'var(--color-text-muted)', fontSize: '0.88rem', margin: 0 }}>
            "{target.description}" şablonunu silmek istediğinize emin misiniz?
          </p>
        </div>
        <div className="modal-footer" style={{ padding: '0 1.25rem 1.1rem' }}>
          <button type="button" className="btn-ghost" onClick={onClose} disabled={deleting}>Vazgeç</button>
          <button type="button" className="btn-danger" onClick={handleDelete} disabled={deleting}>
            {deleting ? <><span className="loader" /> Siliniyor...</> : 'Sil'}
          </button>
        </div>
      </div>
    </div>,
    document.body
  )
}

function RecurringFormModal({ existing, accounts, onClose, onSave }) {
  const [type, setType] = useState(existing?.type || 'Gider')
  const [description, setDescription] = useState(existing?.description || '')
  const [category, setCategory] = useState(existing?.category || '')
  const [amount, setAmount] = useState(existing ? String(existing.amount) : '')
  const [accountId, setAccountId] = useState(
    existing ? (existing.type === 'Gider' ? existing.from_account : existing.to_account) || '' : '',
  )
  const [interval, setInterval_] = useState(existing?.interval || 'monthly')
  const [dayOfMonth, setDayOfMonth] = useState(existing?.day_of_month || 1)
  const [nextDueDate, setNextDueDate] = useState(existing?.next_due_date || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!description.trim()) {
      setErr('Açıklama zorunludur.')
      return
    }
    if (num(amount) <= 0) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    if (!nextDueDate) {
      setErr('Sıradaki vade tarihini seçin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      const body = {
        type,
        description: description.trim(),
        category,
        amount: num(amount),
        from_account: type === 'Gider' ? (accountId ? Number(accountId) : null) : null,
        to_account: type !== 'Gider' ? (accountId ? Number(accountId) : null) : null,
        interval,
        day_of_month: dayOfMonth,
        next_due_date: nextDueDate,
      }
      await onSave(body)
      onClose()
    } catch {
      setErr('Kayıt başarısız oldu. Lütfen tekrar deneyin.')
    } finally {
      setSaving(false)
    }
  }

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">{existing ? 'Şablonu Düzenle' : 'Yeni Tekrarlayan İşlem'}</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Tür</label>
              <select className="form-input" value={type} onChange={(e) => setType(e.target.value)}>
                {Object.entries(TYPE_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Açıklama</label>
              <input className="form-input" type="text" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Örn. Ofis kirası" />
            </div>
            <div className="form-group">
              <label className="form-label">Kategori</label>
              <input className="form-input" type="text" value={category} onChange={(e) => setCategory(e.target.value)} placeholder="Örn. Genel Gider" />
            </div>
            <div className="form-group">
              <label className="form-label">Tutar (₺)</label>
              <input className="form-input" type="number" min="0" step="0.01" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">{type === 'Gider' ? 'Ödeme Kaynağı' : 'Hedef Hesap'}</label>
              <select className="form-input" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                <option value="">Seçiniz (opsiyonel)</option>
                {accounts.map((a) => (
                  <option key={a.id} value={a.id}>{a.name}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Tekrar Sıklığı</label>
              <select className="form-input" value={interval} onChange={(e) => setInterval_(e.target.value)}>
                {Object.entries(INTERVAL_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            {interval === 'monthly' && (
              <div className="form-group">
                <label className="form-label">Ayın Günü</label>
                <select className="form-input" value={dayOfMonth} onChange={(e) => setDayOfMonth(Number(e.target.value))}>
                  {Array.from({ length: 28 }, (_, i) => i + 1).map((d) => (
                    <option key={d} value={d}>{d}</option>
                  ))}
                </select>
              </div>
            )}
            <div className="form-group">
              <label className="form-label">Sıradaki Vade Tarihi</label>
              <input className="form-input" type="date" value={nextDueDate} onChange={(e) => setNextDueDate(e.target.value)} />
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
    </div>,
    document.body
  )
}

export default function RecurringTransactions() {
  const { recurringTransactions, accounts, addRecurringTransaction, updateRecurringTransaction, deleteRecurringTransaction, loading, loaded } = useData()
  const [formTarget, setFormTarget] = useState(undefined) // undefined = closed, null = create, object = edit
  const [deleteTarget, setDeleteTarget] = useState(null)

  const sorted = useMemo(
    () => [...recurringTransactions].sort((a, b) => (a.next_due_date || '').localeCompare(b.next_due_date || '')),
    [recurringTransactions],
  )

  const handleDelete = (id, label) => {
    setDeleteTarget({ id, description: label })
  }

  const confirmDelete = async (id) => {
    try {
      await deleteRecurringTransaction(id)
      setDeleteTarget(null)
    } catch {
      throw new Error('Şablon silinemedi.')
    }
  }

  const handleSave = async (body) => {
    if (formTarget && formTarget.id) {
      await updateRecurringTransaction(formTarget.id, body)
    } else {
      await addRecurringTransaction(body)
    }
  }

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  return (
    <div>
      <div className="page-header-banner" style={{ background: 'var(--color-primary)', color: '#ffffff' }}>
        <div>
          <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)' }}>TEKRARLAYAN İŞLEMLER</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: '#ffffff' }}>Şablonlar vadesi geldiğinde onayla</div>
        </div>
        <button className="btn-inline-text" style={{ color: '#ffffff' }} onClick={() => setFormTarget(null)}>
          <Plus size={18} /> Yeni Şablon
        </button>
      </div>

      {sorted.length === 0 ? (
        <div className="summary-box" style={{ marginTop: '1.75rem' }}>
          <div className="empty-state">
            <Repeat size={40} />
            <span>Henüz tekrarlayan işlem şablonu yok.</span>
          </div>
        </div>
      ) : (
        <div className="list-group" style={{ marginTop: '1.75rem' }}>
          {sorted.map((r) => (
            <div className="list-item" key={r.id} onClick={() => setFormTarget(r)} style={{ cursor: 'pointer' }}>
              <div className="list-icon-box"><Repeat size={20} className="text-primary" /></div>
              <div className="list-item-content">
                <div className="list-item-title">{r.description || r.category}</div>
                <div className="list-item-subtitle">{INTERVAL_LABELS[r.interval] || r.interval} • Sıradaki: {r.next_due_date}</div>
              </div>
              <div className="list-item-value">{formatCurrency(r.amount)}</div>
              <button
                className="icon-btn"
                style={{ color: 'var(--color-danger)', marginLeft: '0.5rem' }}
                onClick={(e) => { e.stopPropagation(); handleDelete(r.id, r.description || r.category) }}
                title="Sil"
              >
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      )}

      {formTarget !== undefined && (
        <RecurringFormModal
          existing={formTarget}
          accounts={accounts}
          onClose={() => setFormTarget(undefined)}
          onSave={handleSave}
        />
      )}
      {deleteTarget && (
        <DeleteRecurringModal
          target={deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={confirmDelete}
        />
      )}
    </div>
  )
}
