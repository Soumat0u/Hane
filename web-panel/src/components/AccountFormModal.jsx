import { useState } from 'react'
import { X, Landmark, Banknote, CreditCard, Building2, PiggyBank } from 'lucide-react'

const ACCOUNT_TYPES = [
  { value: 'Banka', icon: Landmark },
  { value: 'Nakit', icon: Banknote },
  { value: 'Kredi Kartı', icon: CreditCard },
  { value: 'BCH', icon: Building2 },
  { value: 'Esnek', icon: PiggyBank },
]

const HAS_LIMIT = new Set(['Kredi Kartı', 'BCH', 'Esnek'])

export default function AccountFormModal({ account, initialType = 'Banka', onClose, onSave }) {
  const [type, setType] = useState(account?.type || initialType)
  const [name, setName] = useState(account?.name || '')
  const [openingBalance, setOpeningBalance] = useState(account ? String(account.opening_balance ?? 0) : '0')
  const [creditLimit, setCreditLimit] = useState(account ? String(account.credit_limit ?? 0) : '0')
  const [accountDetails, setAccountDetails] = useState(account?.account_details || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const detailsLabel = type === 'Banka' ? 'IBAN' : (type === 'Kredi Kartı' ? 'Kart No' : 'Detay')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim()) {
      setErr('Hesap adı zorunludur.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      const body = {
        name: name.trim(),
        type,
        opening_balance: parseFloat(openingBalance) || 0,
        credit_limit: HAS_LIMIT.has(type) ? (parseFloat(creditLimit) || 0) : 0,
        account_details: accountDetails,
      }
      await onSave(body)
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
          <span className="modal-title">{account ? 'Hesabı Düzenle' : 'Yeni Hesap Ekle'}</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Hesap Türü</label>
              <div className="type-chip-grid">
                {ACCOUNT_TYPES.map(({ value, icon: Icon }) => (
                  <button
                    type="button"
                    key={value}
                    className={`type-chip ${type === value ? 'active' : ''}`}
                    onClick={() => setType(value)}
                  >
                    <Icon size={16} /> {value}
                  </button>
                ))}
              </div>
            </div>
            <div className="form-group">
              <label className="form-label">Hesap Adı</label>
              <input className="form-input" type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Örn. Garanti BBVA" autoFocus />
            </div>
            <div className="form-group">
              <label className="form-label">{type === 'Kredi Kartı' ? 'Açılış Borcu' : 'Açılış Bakiyesi'}</label>
              <input className="form-input" type="number" step="0.01" value={openingBalance} onChange={(e) => setOpeningBalance(e.target.value)} />
            </div>
            {HAS_LIMIT.has(type) && (
              <div className="form-group">
                <label className="form-label">Limit</label>
                <input className="form-input" type="number" step="0.01" value={creditLimit} onChange={(e) => setCreditLimit(e.target.value)} />
              </div>
            )}
            <div className="form-group">
              <label className="form-label">{detailsLabel}</label>
              <input className="form-input" type="text" value={accountDetails} onChange={(e) => setAccountDetails(e.target.value)} placeholder="Opsiyonel" />
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
