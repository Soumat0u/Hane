import { useState } from 'react'
import { X } from 'lucide-react'

const KIND_LABELS = { loan: 'Kredi', kgf: 'KGF', other: 'Diğer' }

export default function LoanFormModal({ loan, onClose, onSave }) {
  const [name, setName] = useState(loan?.name || '')
  const [kind, setKind] = useState(loan?.kind || 'loan')
  const [bankName, setBankName] = useState(loan?.bank_name || '')
  const [principal, setPrincipal] = useState(loan ? String(loan.principal ?? '') : '')
  const [totalPayable, setTotalPayable] = useState(loan ? String(loan.total_payable ?? '') : '')
  const [paidAmount, setPaidAmount] = useState(loan ? String(loan.paid_amount ?? '') : '')
  const [interestRate, setInterestRate] = useState(loan ? String(loan.interest_rate ?? '') : '')
  const [termMonths, setTermMonths] = useState(loan ? String(loan.term_months ?? '') : '')
  const [startDate, setStartDate] = useState(loan?.start_date || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim()) {
      setErr('Kredi adı zorunludur.')
      return
    }
    if (!(parseFloat(principal) > 0)) {
      setErr('Lütfen geçerli bir ana para girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onSave({
        name: name.trim(),
        kind,
        bank_name: bankName,
        principal: parseFloat(principal) || 0,
        total_payable: parseFloat(totalPayable) || 0,
        paid_amount: parseFloat(paidAmount) || 0,
        interest_rate: parseFloat(interestRate) || 0,
        term_months: parseInt(termMonths, 10) || 0,
        start_date: startDate,
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
          <span className="modal-title">{loan ? 'Krediyi Düzenle' : 'Yeni Kredi'}</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Kredi Adı</label>
              <input className="form-input" type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Örn. Ziraat Konut Kredisi" autoFocus />
            </div>
            <div className="form-group">
              <label className="form-label">Tür</label>
              <select className="form-input" value={kind} onChange={(e) => setKind(e.target.value)}>
                {Object.entries(KIND_LABELS).map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Banka</label>
              <input className="form-input" type="text" value={bankName} onChange={(e) => setBankName(e.target.value)} placeholder="Örn. Ziraat Bankası" />
            </div>
            <div className="form-group">
              <label className="form-label">Ana Para</label>
              <input className="form-input" type="number" step="0.01" value={principal} onChange={(e) => setPrincipal(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Toplam Geri Ödeme (faiz dahil)</label>
              <input className="form-input" type="number" step="0.01" value={totalPayable} onChange={(e) => setTotalPayable(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Şu ana kadar ödenen</label>
              <input className="form-input" type="number" step="0.01" value={paidAmount} onChange={(e) => setPaidAmount(e.target.value)} />
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
              <div className="form-group">
                <label className="form-label">Faiz %</label>
                <input className="form-input" type="number" step="0.01" value={interestRate} onChange={(e) => setInterestRate(e.target.value)} />
              </div>
              <div className="form-group">
                <label className="form-label">Vade (ay)</label>
                <input className="form-input" type="number" value={termMonths} onChange={(e) => setTermMonths(e.target.value)} />
              </div>
            </div>
            <div className="form-group">
              <label className="form-label">Başlangıç Tarihi</label>
              <input className="form-input" type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
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
