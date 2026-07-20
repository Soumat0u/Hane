import { useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import { useData } from '../context/DataContext'
import { num, parseMoneyInput } from '../utils'
import MoneyInput from './MoneyInput'

/** Mevcut bir kasaya (Nakit hesabı) hızlıca nakit ekler — yeni kasa oluşturmaz. */
export default function AddCashModal({ cashAccounts, onClose }) {
  const { updateAccount } = useData()
  const [accountId, setAccountId] = useState(cashAccounts[0]?.id ?? '')
  const [amount, setAmount] = useState('')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    const parsedAmount = parseMoneyInput(amount)
    if (!accountId) {
      setErr('Lütfen bir kasa seçiniz.')
      return
    }
    if (!parsedAmount || parsedAmount <= 0) {
      setErr('Geçerli bir tutar giriniz.')
      return
    }
    const account = cashAccounts.find((a) => String(a.id) === String(accountId))
    if (!account) return

    setSaving(true)
    setErr('')
    try {
      await updateAccount(account.id, {
        name: account.name,
        type: account.type,
        opening_balance: num(account.opening_balance) + parsedAmount,
        credit_limit: num(account.credit_limit),
        bank_logo_painter: account.bank_logo_painter || '',
        account_details: account.account_details || '',
        is_active: account.is_active,
      })
      onClose()
    } catch {
      setErr('Kayıt başarısız oldu. Lütfen tekrar deneyin.')
      setSaving(false)
    }
  }

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">Nakit Ekle</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="form-group">
              <label className="form-label">Kasa</label>
              <select className="form-input" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                {cashAccounts.map((a) => (
                  <option key={a.id} value={a.id}>{a.name}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Eklenecek Tutar (₺)</label>
              <MoneyInput value={amount} onChange={setAmount} autoFocus />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose} disabled={saving}>İptal</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving}>
              {saving ? <span className="loader" /> : 'Ekle'}
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body
  )
}
