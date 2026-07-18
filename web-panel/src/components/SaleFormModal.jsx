import { useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import MoneyInput from './MoneyInput'
import { parseMoneyInput } from '../utils'

const UNIT_TYPES = { apartment: 'Daire', shop: 'Dükkan', land: 'Arsa', other: 'Diğer' }

export default function SaleFormModal({ projectId, projectName, contacts, onClose, onSaveSale, onSaveReceivable }) {
  const [unitType, setUnitType] = useState('apartment')
  const [unitNo, setUnitNo] = useState('')
  const [salePrice, setSalePrice] = useState('')
  const [buyerId, setBuyerId] = useState('')
  const [saleDate, setSaleDate] = useState('')
  const [createReceivable, setCreateReceivable] = useState(true)
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
      await onSaveSale({
        project: projectId,
        buyer: buyerId ? Number(buyerId) : null,
        unit_type: unitType,
        unit_no: unitNo,
        sale_price: price,
        sale_date: saleDate,
      })
      if (createReceivable && price > 0) {
        await onSaveReceivable({
          kind: 'installment',
          status: 'pending',
          project: projectId,
          contact: buyerId ? Number(buyerId) : null,
          total_amount: price,
          collected_amount: 0,
          due_date: saleDate,
          description: `${UNIT_TYPES[unitType]} ${unitNo} satış bedeli`.trim(),
        })
      }
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
