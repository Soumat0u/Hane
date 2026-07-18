import { useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import { num, parseMoneyInput, formatAmountForDisplay } from '../utils'
import MoneyInput from './MoneyInput'

export const RECURRING_TYPE_LABELS = { Gider: 'Gider', Gelir: 'Gelir', Tahsilat: 'Tahsilat' }
export const RECURRING_INTERVAL_LABELS = { monthly: 'Aylık', weekly: 'Haftalık' }

export function DeleteRecurringModal({ target, onClose, onConfirm }) {
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

/// Tekrarlayan işlem oluşturma/düzenleme formu. Sayfa (RecurringTransactions),
/// takvim paneli ve bildirim çanı gibi farklı yerlerden ortak olarak açılır.
/// `onDelete` verilirse (düzenleme modunda) formun içinden silme de yapılabilir.
export default function RecurringFormModal({ existing, accounts, onClose, onSave, onDelete }) {
  const [type, setType] = useState(existing?.type || 'Gider')
  const [description, setDescription] = useState(existing?.description || '')
  const [category, setCategory] = useState(existing?.category || '')
  const [amount, setAmount] = useState(existing ? formatAmountForDisplay(existing.amount) : '')
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
    if (parseMoneyInput(amount) <= 0) {
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
        amount: parseMoneyInput(amount),
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
                {Object.entries(RECURRING_TYPE_LABELS).map(([k, label]) => (
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
              <MoneyInput value={amount} onChange={setAmount} />
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
                {Object.entries(RECURRING_INTERVAL_LABELS).map(([k, label]) => (
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
          <div className="modal-footer" style={{ justifyContent: existing && onDelete ? 'space-between' : undefined }}>
            {existing && onDelete && (
              <button type="button" className="btn-danger" onClick={() => onDelete(existing)} disabled={saving}>
                Şablonu Sil
              </button>
            )}
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button type="button" className="btn-secondary" onClick={onClose} disabled={saving}>İptal</button>
              <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving}>
                {saving ? <span className="loader" /> : 'Kaydet'}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>,
    document.body
  )
}
