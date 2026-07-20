import { useState, useRef, useEffect } from 'react'
import { createPortal } from 'react-dom'
import { X, Landmark, Banknote, CreditCard, ChevronDown } from 'lucide-react'
import BankLogo from './BankLogo'
import MoneyInput from './MoneyInput'
import { parseMoneyInput, formatAmountForDisplay } from '../utils'

// Mobil uygulamadaki `yeni_hesap_view.dart` ile aynı banka listesi.
const BANKS = [
  'Ziraat Bankası', 'Garanti BBVA', 'Halkbank', 'Akbank', 'Yapı Kredi',
  'İş Bankası', 'VakıfBank', 'QNB Finansbank', 'DenizBank', 'TEB',
  'Kuveyt Türk', 'Enpara', 'Şekerbank', 'ING', 'Fibabanka', 'Albaraka Türk',
  'Odeabank', 'Alternatif Bank', 'Anadolubank', 'HSBC', 'Türkiye Finans', 'Diğer',
]

// Mobildeki `_IbanInputFormatter` ile aynı mantık: "TR" öneki sabit kalır,
// karakterler büyük harfe çevrilir, her 4 karakterde bir boşluk eklenir.
// Türkiye IBAN'ları 26 karakterdir (TR + 24 hane).
function formatIban(rawInput, prevDigitsBeforeCursor) {
  let raw = rawInput.toUpperCase().replace(/[^A-Z0-9]/g, '')
  if (!raw.startsWith('TR')) {
    raw = 'TR' + raw.replace(/^T?R?/, '')
  }
  if (raw.length > 26) raw = raw.slice(0, 26)

  let formatted = ''
  for (let i = 0; i < raw.length; i++) {
    if (i > 0 && i % 4 === 0) formatted += ' '
    formatted += raw[i]
  }

  let newOffset = 0
  let seenDigits = 0
  for (let i = 0; i < formatted.length; i++) {
    if (seenDigits >= prevDigitsBeforeCursor) break
    if (formatted[i] !== ' ') seenDigits++
    newOffset = i + 1
  }
  newOffset = Math.max(2, Math.min(newOffset, formatted.length))

  return { formatted, cursor: newOffset }
}

function formatCardNumber(rawInput) {
  let text = rawInput.replace(/ /g, '').replace(/\D/g, '')
  if (text.length > 16) text = text.slice(0, 16)
  
  let formatted = ''
  for (let i = 0; i < text.length; i++) {
    if (i > 0 && i % 4 === 0) formatted += ' '
    formatted += text[i]
  }
  return formatted
}

const MOBILE_TYPES = ['Banka', 'Kredi Kartı', 'Nakit']
const TYPE_ICONS = { 'Banka': Landmark, 'Kredi Kartı': CreditCard, 'Nakit': Banknote }
const HAS_LIMIT = new Set(['Kredi Kartı', 'BCH', 'Esnek'])

function BankPicker({ value, onChange, error }) {
  const [open, setOpen] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    const onClick = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false) }
    document.addEventListener('mousedown', onClick)
    return () => document.removeEventListener('mousedown', onClick)
  }, [])

  return (
    <div className="form-group" ref={ref} style={{ position: 'relative' }}>
      <label className="form-label">Banka Seçiniz</label>
      <button
        type="button"
        className="form-input"
        onClick={() => setOpen((o) => !o)}
        style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', textAlign: 'left', cursor: 'pointer', borderColor: error ? 'var(--color-danger)' : undefined }}
      >
        {value ? (
          <>
            <BankLogo bankName={value} width={26} height={26} />
            <span style={{ flex: 1, color: 'var(--color-text-main)' }}>{value}</span>
          </>
        ) : (
          <span style={{ flex: 1, color: 'var(--color-text-muted)' }}>Banka seçin</span>
        )}
        <ChevronDown size={16} color="var(--color-text-muted)" />
      </button>
      {error && <div style={{ color: 'var(--color-danger)', fontSize: '0.75rem', marginTop: '0.3rem' }}>{error}</div>}
      {open && (
        <div
          style={{
            position: 'absolute', top: '100%', left: 0, right: 0, marginTop: '0.4rem', zIndex: 20,
            background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)',
            boxShadow: 'var(--shadow-xl)', maxHeight: 280, overflowY: 'auto',
          }}
        >
          {BANKS.map((bank) => (
            <div
              key={bank}
              onClick={() => { onChange(bank); setOpen(false) }}
              style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', padding: '0.6rem 0.9rem', cursor: 'pointer' }}
              onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--color-surface-hover)' }}
              onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent' }}
            >
              <BankLogo bankName={bank} width={28} height={28} />
              <span style={{ fontWeight: 600, color: 'var(--color-text-main)', fontSize: '0.9rem' }}>{bank}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default function AccountFormModal({ account, initialType = 'Banka', lockType = false, onClose, onSave }) {
  const isEditing = Boolean(account)
  const isMobileType = MOBILE_TYPES.includes(account?.type || initialType)

  const [type, setType] = useState(account?.type || initialType)
  const [selectedBank, setSelectedBank] = useState(account?.bank_logo_painter || '')
  const [name, setName] = useState(account?.name || '')
  const [balance, setBalance] = useState(account ? formatAmountForDisplay(account.opening_balance ?? 0) : '0')
  const [creditLimit, setCreditLimit] = useState(account ? formatAmountForDisplay(account.credit_limit ?? 0) : '0')
  const [debt, setDebt] = useState(account && account.type === 'Kredi Kartı' ? formatAmountForDisplay(-(account.opening_balance ?? 0)) : '0')
  const [iban, setIban] = useState(() => {
    if (account?.type === 'Banka' && account.account_details) return formatIban(account.account_details, 26).formatted
    return 'TR'
  })
  const [cardNumber, setCardNumber] = useState(() => {
    if (account?.type === 'Kredi Kartı' && account.account_details) {
      const clean = account.account_details.replace(/ /g, '')
      if (clean.length === 16 && !clean.includes('*')) {
        return formatCardNumber(clean)
      } else {
        return clean.includes('*') ? '' : clean
      }
    }
    return ''
  })
  const [accountDetails, setAccountDetails] = useState(account?.account_details || '') // BCH/Esnek gibi mobil-dışı türler için serbest alan
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')
  const [bankErr, setBankErr] = useState('')
  const ibanInputRef = useRef(null)

  const handleTypeChange = (nextType) => {
    setType(nextType)
    setSelectedBank('')
    setName('')
    setBalance('0')
    setCreditLimit('0')
    setDebt('0')
    setIban('TR')
    setCardNumber('')
    setBankErr('')
  }

  const handleIbanChange = (e) => {
    const el = e.target
    const cursor = el.selectionStart ?? el.value.length
    const digitsBeforeCursor = el.value.slice(0, cursor).replace(/ /g, '').length
    const { formatted, cursor: newCursor } = formatIban(el.value, digitsBeforeCursor)
    setIban(formatted)
    requestAnimationFrame(() => {
      if (ibanInputRef.current) ibanInputRef.current.setSelectionRange(newCursor, newCursor)
    })
  }

  const requiresBank = type === 'Banka' || type === 'Kredi Kartı'

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim()) {
      setErr('Hesap adı zorunludur.')
      return
    }
    if (requiresBank && !selectedBank) {
      setBankErr('Lütfen bir banka seçiniz.')
      return
    }
    if (type === 'Banka' && iban.replace(/ /g, '').length < 26) {
      setErr('Geçerli bir IBAN giriniz.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      let openingBalance = 0
      let details = ''
      if (type === 'Banka') {
        openingBalance = parseMoneyInput(balance)
        details = iban.replace(/ /g, '')
      } else if (type === 'Kredi Kartı') {
        openingBalance = -parseMoneyInput(debt)
        details = cardNumber.replace(/ /g, '')
      } else if (type === 'Nakit') {
        openingBalance = parseMoneyInput(balance)
      } else {
        // BCH / Esnek (yalnızca web panelinden düzenlenebilen, mobilde olmayan türler)
        openingBalance = parseMoneyInput(balance)
        details = accountDetails
      }

      const body = {
        name: name.trim(),
        type,
        opening_balance: openingBalance,
        credit_limit: HAS_LIMIT.has(type) ? parseMoneyInput(creditLimit) : 0,
        account_details: details,
        bank_logo_painter: requiresBank ? selectedBank : '',
      }
      await onSave(body)
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
          <span className="modal-title">
            {isEditing 
              ? `${account.name} Düzenle` 
              : (lockType ? `Yeni ${initialType} Ekle` : 'Yeni Hesap Ekle')}
          </span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}

            {!lockType && !isEditing ? (
              <div className="form-group">
                <label className="form-label">Hesap Türü</label>
                <div className="type-chip-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
                  {MOBILE_TYPES.map((value) => {
                    const Icon = TYPE_ICONS[value]
                    return (
                      <button
                        type="button"
                        key={value}
                        className={`type-chip ${type === value ? 'active' : ''}`}
                        onClick={() => handleTypeChange(value)}
                        disabled={isEditing}
                      >
                        <Icon size={16} /> {value}
                      </button>
                    )
                  })}
                </div>
              </div>
            ) : null}

            {requiresBank && (
              <BankPicker value={selectedBank} onChange={(b) => { setSelectedBank(b); setBankErr('') }} error={bankErr} />
            )}

            <div className="form-group">
              <label className="form-label">
                {type === 'Banka' ? 'Hesap / Kart Adı (Maaş Hesabı vb.)'
                  : type === 'Kredi Kartı' ? 'Kart Adı (Bonus, Axess vb.)'
                  : type === 'Nakit' ? 'Kasa Adı (Merkez Kasa vb.)'
                  : 'Hesap Adı'}
              </label>
              <input className="form-input" type="text" value={name} onChange={(e) => setName(e.target.value)} autoFocus />
            </div>

            {(type === 'Banka' || type === 'Nakit') && (
              <div className="form-group">
                <label className="form-label">Güncel Bakiye (₺)</label>
                <MoneyInput value={balance} onChange={setBalance} />
              </div>
            )}

            {type === 'Banka' && (
              <div className="form-group">
                <label className="form-label">IBAN</label>
                <input
                  ref={ibanInputRef}
                  className="form-input"
                  type="text"
                  value={iban}
                  onChange={handleIbanChange}
                  style={{ fontFamily: 'monospace', letterSpacing: '0.03em' }}
                />
              </div>
            )}

            {type === 'Kredi Kartı' && (
              <>
                <div className="form-group">
                  <label className="form-label">Kart Numarası (16 Hane)</label>
                  <input
                    className="form-input"
                    type="text"
                    inputMode="numeric"
                    maxLength={19} // 16 digits + 3 spaces
                    value={cardNumber}
                    onChange={(e) => setCardNumber(formatCardNumber(e.target.value))}
                    style={{ letterSpacing: '0.05em' }}
                  />
                </div>
                <div style={{ display: 'flex', gap: '1rem' }}>
                  <div className="form-group" style={{ flex: 1 }}>
                    <label className="form-label">Kart Limiti (₺)</label>
                    <MoneyInput value={creditLimit} onChange={setCreditLimit} />
                  </div>
                  <div className="form-group" style={{ flex: 1 }}>
                    <label className="form-label">Güncel Borç (₺)</label>
                    <MoneyInput value={debt} onChange={setDebt} />
                  </div>
                </div>
              </>
            )}

            {(type === 'BCH' || type === 'Esnek') && (
              <>
                <div className="form-group">
                  <label className="form-label">Güncel Bakiye (₺)</label>
                  <MoneyInput value={balance} onChange={setBalance} />
                </div>
                <div className="form-group">
                  <label className="form-label">Limit</label>
                  <MoneyInput value={creditLimit} onChange={setCreditLimit} />
                </div>
                <div className="form-group">
                  <label className="form-label">Detay</label>
                  <input className="form-input" type="text" value={accountDetails} onChange={(e) => setAccountDetails(e.target.value)} placeholder="Opsiyonel" />
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
