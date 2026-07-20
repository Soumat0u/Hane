import { useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import MoneyInput from './MoneyInput'
import { parseMoneyInput, formatAmountForDisplay } from '../utils'

const DIRECTION_LABELS = { received: 'Alınan Çek', issued: 'Verilen Çek' }
const STATUS_LABELS = {
  portfolio: 'Portföyde',
  deposited: 'Tahsile Verildi',
  cashed: 'Tahsil Edildi',
  given: 'Ciro/Ödendi',
  bounced: 'Karşılıksız',
}

export default function ChequeFormModal({ cheque, contacts, onClose, onSave }) {
  const [direction, setDirection] = useState(cheque?.direction || 'received')
  const [status, setStatus] = useState(cheque?.status || 'portfolio')
  const [amount, setAmount] = useState(cheque ? formatAmountForDisplay(cheque.amount ?? 0) : '')
  const [bankName, setBankName] = useState(cheque?.bank_name || '')
  const [serialNo, setSerialNo] = useState(cheque?.serial_no || '')
  const [dueDate, setDueDate] = useState(cheque?.due_date || '')
  const [contactId, setContactId] = useState(cheque?.contact || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!(parseMoneyInput(amount) > 0)) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onSave({
        direction,
        status,
        amount: parseMoneyInput(amount),
        bank_name: bankName,
        serial_no: serialNo,
        due_date: dueDate,
        contact: contactId ? Number(contactId) : null,
      })
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
          <span className="modal-title">{cheque ? 'Çeki Düzenle' : 'Yeni Çek'}</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Çek Türü</label>
              <select className="form-input" value={direction} onChange={(e) => setDirection(e.target.value)}>
                {Object.entries(DIRECTION_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Tutar</label>
              <MoneyInput value={amount} onChange={setAmount} autoFocus />
            </div>
            <div className="form-group">
              <label className="form-label">Banka</label>
              <input className="form-input" type="text" value={bankName} onChange={(e) => setBankName(e.target.value)} placeholder="Örn. Garanti BBVA" />
            </div>
            <div className="form-group">
              <label className="form-label">Seri No</label>
              <input className="form-input" type="text" value={serialNo} onChange={(e) => setSerialNo(e.target.value)} placeholder="Opsiyonel" />
            </div>
            <div className="form-group">
              <label className="form-label">Durum</label>
              <select className="form-input" value={status} onChange={(e) => setStatus(e.target.value)}>
                {Object.entries(STATUS_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Vade Tarihi</label>
              <input className="form-input" type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} />
            </div>
            {contacts.length > 0 && (
              <div className="form-group">
                <label className="form-label">Cari (Müşteri/Tedarikçi)</label>
                <select className="form-input" value={contactId} onChange={(e) => setContactId(e.target.value)}>
                  <option value="">Seçiniz (opsiyonel)</option>
                  {contacts.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
            )}
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
