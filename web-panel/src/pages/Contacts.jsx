import { useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { useNavigate } from 'react-router-dom'
import { UserPlus, X } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'

export const CONTACT_KIND_LABELS = {
  supplier: 'Tedarikçi',
  customer: 'Müşteri',
  subcontractor: 'Taşeron',
  government: 'Devlet',
  bank: 'Banka',
  other: 'Diğer',
}

export function ContactFormModal({ contact, onClose, onSave }) {
  const [name, setName] = useState(contact?.name || '')
  const [kind, setKind] = useState(contact?.kind || 'supplier')
  const [phone, setPhone] = useState(contact?.phone || '')
  const [email, setEmail] = useState(contact?.email || '')
  const [taxNumber, setTaxNumber] = useState(contact?.tax_number || '')
  const [note, setNote] = useState(contact?.note || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim()) {
      setErr('Ad / Unvan zorunludur.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onSave({ name: name.trim(), kind, phone, email, tax_number: taxNumber, note })
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
          <span className="modal-title">{contact ? 'Cariyi Düzenle' : 'Yeni Cari Ekle'}</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Ad / Unvan</label>
              <input className="form-input" type="text" value={name} onChange={(e) => setName(e.target.value)} autoFocus />
            </div>
            <div className="form-group">
              <label className="form-label">Tür</label>
              <select className="form-input" value={kind} onChange={(e) => setKind(e.target.value)}>
                {Object.entries(CONTACT_KIND_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Telefon</label>
              <input className="form-input" type="text" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="Opsiyonel" />
            </div>
            <div className="form-group">
              <label className="form-label">E-posta</label>
              <input className="form-input" type="text" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Opsiyonel" />
            </div>
            <div className="form-group">
              <label className="form-label">Vergi No</label>
              <input className="form-input" type="text" value={taxNumber} onChange={(e) => setTaxNumber(e.target.value)} placeholder="Opsiyonel" />
            </div>
            <div className="form-group">
              <label className="form-label">Not</label>
              <textarea className="form-input" rows={2} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Opsiyonel" />
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

export default function Contacts() {
  const navigate = useNavigate()
  const { contacts, addContact } = useData()
  const [modalOpen, setModalOpen] = useState(false)

  const byKind = useMemo(() => {
    const map = {}
    for (const kind of Object.keys(CONTACT_KIND_LABELS)) map[kind] = []
    contacts.forEach((c) => {
      const kind = CONTACT_KIND_LABELS[c.kind] ? c.kind : 'other'
      map[kind].push(c)
    })
    return map
  }, [contacts])

  const hasAny = contacts.length > 0

  const handleSave = async (body) => {
    await addContact(body)
  }

  return (
    <div>
      <div className="page-header-banner" style={{ background: 'var(--color-primary)', color: '#ffffff' }}>
        <div>
          <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)' }}>CARİ HESAPLAR</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: '#ffffff' }}>Tedarikçi, Müşteri ve Diğer Cariler</div>
        </div>
        <button className="btn-inline-text" style={{ color: '#ffffff' }} onClick={() => setModalOpen(true)}>
          <UserPlus size={18} /> Yeni Cari
        </button>
      </div>

      {!hasAny ? (
        <div className="summary-box" style={{ marginTop: '1.75rem' }}>
          <div className="empty-state">
            <span>Henüz cari hesap bulunmuyor.</span>
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', marginTop: '1.75rem' }}>
          {Object.entries(CONTACT_KIND_LABELS).map(([kind, label]) => {
            const list = byKind[kind]
            if (!list || list.length === 0) return null
            return (
              <div key={kind}>
                <div className="section-header">
                  <span className="section-title">{label.toUpperCase()}</span>
                </div>
                <div className="list-group">
                  {list.map((c) => {
                    const balance = num(c.balance)
                    const isDebt = balance > 0
                    const isCredit = balance < 0
                    const color = isDebt ? 'var(--color-danger)' : (isCredit ? 'var(--color-success)' : 'var(--color-text-muted)')
                    const tag = isDebt ? 'Borcumuz' : (isCredit ? 'Alacağımız' : '')
                    return (
                      <div className="list-item" key={c.id} onClick={() => navigate(`/dashboard/contacts/${c.id}`)} style={{ cursor: 'pointer' }}>
                        <div className="list-item-content">
                          <div className="list-item-title">{c.name}</div>
                        </div>
                        <div className="list-item-value-box">
                          <div className="list-item-value" style={{ color }}>{formatCurrency(Math.abs(balance))}</div>
                          {tag && <div style={{ fontSize: '0.75rem', color }}>{tag}</div>}
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {modalOpen && (
        <ContactFormModal onClose={() => setModalOpen(false)} onSave={handleSave} />
      )}
    </div>
  )
}
