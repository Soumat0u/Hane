import { useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import MoneyInput from './MoneyInput'
import { parseMoneyInput } from '../utils'

const UNIT_TYPES = { apartment: 'Daire', shop: 'Dükkan', land: 'Arsa', other: 'Diğer' }

export default function SaleFormModal({ projectId, projectName, contacts, onClose, onSaveSale }) {
  const [unitType, setUnitType] = useState('apartment')
  const [unitNo, setUnitNo] = useState('')
  const [salePrice, setSalePrice] = useState('')
  const [buyerId, setBuyerId] = useState('')
  const [saleDate, setSaleDate] = useState('')
  const [createReceivable, setCreateReceivable] = useState(true)
  const [downPayment, setDownPayment] = useState('')
  const [installmentCount, setInstallmentCount] = useState('')
  const [firstDueDate, setFirstDueDate] = useState('')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    const price = parseMoneyInput(salePrice)
    if (price <= 0) {
      setErr('Lütfen geçerli bir satış fiyatı girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      // Satış ve varsa taksit planı (Receivable satırları) sunucuda tek atomik
      // istekte, doğru `sale` bağlantısıyla oluşturulur (bkz. SaleViewSet.create).
      await onSaveSale({
        project: projectId,
        buyer: buyerId ? Number(buyerId) : null,
        unit_type: unitType,
        unit_no: unitNo,
        sale_price: price,
        sale_date: saleDate,
        down_payment: parseMoneyInput(downPayment) || 0,
        installment_count: installmentCount ? Number(installmentCount) : 0,
        first_due_date: firstDueDate || saleDate,
        create_receivable: createReceivable,
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
          <span className="modal-title">Yeni Satış</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div style={{ marginBottom: '1rem', color: 'var(--color-text-muted)', fontSize: '0.9rem' }}>
              Proje: <strong>{projectName}</strong>
            </div>
            <div className="form-group">
              <label className="form-label">Birim Türü</label>
              <select className="form-input" value={unitType} onChange={(e) => setUnitType(e.target.value)}>
                {Object.entries(UNIT_TYPES).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Birim No</label>
              <input className="form-input" type="text" value={unitNo} onChange={(e) => setUnitNo(e.target.value)} placeholder="Örn. A-12" />
            </div>
            <div className="form-group">
              <label className="form-label">Satış Fiyatı</label>
              <MoneyInput value={salePrice} onChange={setSalePrice} autoFocus />
            </div>
            {contacts.length > 0 && (
              <div className="form-group">
                <label className="form-label">Alıcı (Cari)</label>
                <select className="form-input" value={buyerId} onChange={(e) => setBuyerId(e.target.value)}>
                  <option value="">Seçiniz (opsiyonel)</option>
                  {contacts.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
            )}
            <div className="form-group">
              <label className="form-label">Satış Tarihi</label>
              <input className="form-input" type="date" value={saleDate} onChange={(e) => setSaleDate(e.target.value)} />
            </div>
            <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.9rem', marginTop: '0.5rem' }}>
              <input type="checkbox" checked={createReceivable} onChange={(e) => setCreateReceivable(e.target.checked)} />
              Satış bedeli için alacak oluştur
            </label>

            {createReceivable && (
              <>
                <div className="form-group" style={{ marginTop: '1rem' }}>
                  <label className="form-label">Peşinat (opsiyonel)</label>
                  <MoneyInput value={downPayment} onChange={setDownPayment} placeholder="0" />
                </div>
                <div className="form-group">
                  <label className="form-label">Taksit Sayısı (opsiyonel)</label>
                  <input
                    className="form-input"
                    type="number"
                    min="0"
                    value={installmentCount}
                    onChange={(e) => setInstallmentCount(e.target.value)}
                    placeholder="Boş bırakılırsa tek kalemde alacak oluşur"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">İlk Taksit Vadesi (opsiyonel)</label>
                  <input className="form-input" type="date" value={firstDueDate} onChange={(e) => setFirstDueDate(e.target.value)} />
                  <span style={{ fontSize: '0.78rem', color: 'var(--color-text-muted)' }}>
                    Sonraki taksitler ilk vadeden başlayarak birer ay arayla otomatik planlanır.
                  </span>
                </div>
              </>
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
