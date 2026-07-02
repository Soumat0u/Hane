import { useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { X } from 'lucide-react'
import { useData } from '../context/DataContext'
import { num } from '../utils'

const today = () => new Date().toISOString().slice(0, 10)

function AccountOptions({ accounts, types }) {
  const groups = types.map((type) => ({
    type,
    items: accounts.filter((a) => a.type === type),
  })).filter((g) => g.items.length > 0)

  return groups.map((g) => (
    <optgroup key={g.type} label={g.type.toUpperCase()}>
      {g.items.map((a) => (
        <option key={a.id} value={a.name}>{a.name}</option>
      ))}
    </optgroup>
  ))
}

/**
 * Mobildeki `YeniIslemScreen`'in web karşılığı: sol panelden seçilen türe göre
 * (Ödeme, Transfer, Borçlanma, Kredi Kullanımı, Satış) doğru formu gösterir.
 */
export default function NewTransactionFormModal({ type: rawType, onClose }) {
  const type = rawType === 'Borç' ? 'Borçlanma' : rawType
  const { projects, accounts, categories, addTransaction, addLoan, addDebt } = useData()
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  // --- Ödeme (Gelir/Gider — Tahsilat da bu formun gelir tarafıdır) ---
  const [isIncome, setIsIncome] = useState(false)
  const [odemeDate, setOdemeDate] = useState(today())
  const [odemeProject, setOdemeProject] = useState('')
  const [mainCategory, setMainCategory] = useState('')
  const [subCategory, setSubCategory] = useState('')
  const [odemeAccount, setOdemeAccount] = useState('')
  const [counterparty, setCounterparty] = useState('')
  const [odemeAmount, setOdemeAmount] = useState('')
  const [quantity, setQuantity] = useState('')
  const [unit, setUnit] = useState('')
  const [odemeDesc, setOdemeDesc] = useState('')

  const mainCategories = useMemo(
    () => categories.filter((c) => !c.parent && (isIncome ? c.type === 'income' : c.type === 'cost')),
    [categories, isIncome],
  )
  const subCategories = useMemo(() => {
    const parent = mainCategories.find((c) => c.name === mainCategory)
    return parent ? categories.filter((c) => c.parent === parent.id) : []
  }, [categories, mainCategories, mainCategory])

  // --- Transfer ---
  const [transferDate, setTransferDate] = useState(today())
  const [fromAccount, setFromAccount] = useState('')
  const [toAccount, setToAccount] = useState('')
  const [transferAmount, setTransferAmount] = useState('')
  const [transferDesc, setTransferDesc] = useState('')

  // --- Borçlanma ---
  const [debtContact, setDebtContact] = useState('')
  const [debtAmount, setDebtAmount] = useState('')
  const [debtDueDate, setDebtDueDate] = useState('')
  const [debtProject, setDebtProject] = useState('')
  const [debtDesc, setDebtDesc] = useState('')

  // --- Kredi Kullanımı ---
  const [krediDate, setKrediDate] = useState(today())
  const [krediBank, setKrediBank] = useState('')
  const [krediProject, setKrediProject] = useState('')
  const [krediAmount, setKrediAmount] = useState('')
  const [krediTermMonths, setKrediTermMonths] = useState('')
  const [krediDesc, setKrediDesc] = useState('')

  // --- Satış ---
  const [satisDate, setSatisDate] = useState(today())
  const [satisProject, setSatisProject] = useState('')
  const [satisCustomer, setSatisCustomer] = useState('')
  const [satisUnit, setSatisUnit] = useState('')
  const [satisPrice, setSatisPrice] = useState('')
  const [satisDownPayment, setSatisDownPayment] = useState('')
  const [satisDesc, setSatisDesc] = useState('')

  const projectIdByName = (name) => {
    const p = projects.find((x) => x.name === name)
    return p ? p.id : null
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErr('')
    setSaving(true)
    try {
      if (type === 'Ödeme') {
        if (num(odemeAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        await addTransaction({
          project_id: projectIdByName(odemeProject),
          type: isIncome ? 'Gelir' : 'Gider',
          category: subCategory || mainCategory || '',
          amount: num(odemeAmount),
          date: odemeDate,
          source_name: odemeAccount,
          contact_name: counterparty,
          description: odemeDesc,
          quantity: quantity ? num(quantity) : null,
          unit,
        })
      } else if (type === 'Transfer') {
        if (num(transferAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        await addTransaction({
          type: 'Transfer',
          category: 'Transfer',
          amount: num(transferAmount),
          date: transferDate,
          source_name: fromAccount,
          dest_name: toAccount,
          description: transferDesc,
        })
      } else if (type === 'Borçlanma') {
        if (num(debtAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        await addDebt({
          amount: num(debtAmount),
          contactName: debtContact,
          dueDate: debtDueDate,
          projectId: projectIdByName(debtProject),
          description: debtDesc,
        })
      } else if (type === 'Kredi Kullanımı') {
        if (num(krediAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        await addTransaction({
          project_id: projectIdByName(krediProject),
          type: 'Kredi Kullanımı',
          category: 'Kredi Kullanımı',
          amount: num(krediAmount),
          date: krediDate,
          source_name: krediBank,
          description: krediDesc,
        })
        await addLoan({
          name: `${krediBank} Kredisi`,
          kind: 'loan',
          bank_name: krediBank,
          principal: num(krediAmount),
          total_payable: num(krediAmount),
          term_months: krediTermMonths ? Number(krediTermMonths) : 0,
          start_date: krediDate,
        })
      } else if (type === 'Satış') {
        if (num(satisPrice) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        const extras = [satisUnit, satisDownPayment ? `Peşinat: ₺${satisDownPayment}` : ''].filter(Boolean).join(' • ')
        await addTransaction({
          project_id: projectIdByName(satisProject),
          type: 'Satış',
          category: 'Satış',
          amount: num(satisPrice),
          date: satisDate,
          contact_name: satisCustomer,
          description: extras ? `${extras}${satisDesc ? ' • ' + satisDesc : ''}` : satisDesc,
        })
      }
      onClose()
    } catch (ex) {
      setErr(ex?.message || 'Kaydedilemedi. Lütfen tekrar deneyin.')
    } finally {
      setSaving(false)
    }
  }

  const renderFields = () => {
    if (type === 'Ödeme') {
      return (
        <>
          <div className="form-group">
            <label className="form-label">Tarih</label>
            <input type="date" className="form-input" value={odemeDate} onChange={(e) => setOdemeDate(e.target.value)} />
          </div>

          <div className="form-group">
            <label className="form-label">Gelir / Gider</label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
              <button
                type="button"
                className={`type-chip ${isIncome ? 'active' : ''}`}
                style={{ flexDirection: 'row', justifyContent: 'center' }}
                onClick={() => { setIsIncome(true); setMainCategory(''); setSubCategory('') }}
              >
                Gelir
              </button>
              <button
                type="button"
                className={`type-chip ${!isIncome ? 'active' : ''}`}
                style={{ flexDirection: 'row', justifyContent: 'center' }}
                onClick={() => { setIsIncome(false); setMainCategory(''); setSubCategory('') }}
              >
                Gider
              </button>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Proje (opsiyonel)</label>
            <select className="form-input" value={odemeProject} onChange={(e) => setOdemeProject(e.target.value)}>
              <option value="">Proje seçilmedi</option>
              {projects.map((p) => <option key={p.id} value={p.name}>{p.name}</option>)}
            </select>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Ana Kategori</label>
              <select className="form-input" value={mainCategory} onChange={(e) => { setMainCategory(e.target.value); setSubCategory('') }}>
                <option value="">Seçiniz</option>
                {mainCategories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Alt Kategori</label>
              <select className="form-input" value={subCategory} onChange={(e) => setSubCategory(e.target.value)} disabled={subCategories.length === 0}>
                <option value="">Seçiniz (opsiyonel)</option>
                {subCategories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">{isIncome ? 'Tahsilat Hesabı' : 'Ödeme Kaynağı'}</label>
            <select className="form-input" value={odemeAccount} onChange={(e) => setOdemeAccount(e.target.value)}>
              <option value="">Seçiniz</option>
              <AccountOptions accounts={accounts} types={['Banka', 'Kredi Kartı', 'Nakit']} />
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">{isIncome ? 'Müşteri' : 'Alıcı / Satıcı'}</label>
            <input type="text" className="form-input" value={counterparty} onChange={(e) => setCounterparty(e.target.value)} placeholder={isIncome ? 'Müşteri adı' : 'Betoncu'} />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Tutar (₺)</label>
              <input type="number" min="0" step="0.01" className="form-input" value={odemeAmount} onChange={(e) => setOdemeAmount(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Miktar (opsiyonel)</label>
              <input type="number" className="form-input" value={quantity} onChange={(e) => setQuantity(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Birim</label>
              <input type="text" className="form-input" placeholder="kg, adet, m2..." value={unit} onChange={(e) => setUnit(e.target.value)} />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Açıklama</label>
            <textarea className="form-input textarea-field" rows={2} value={odemeDesc} onChange={(e) => setOdemeDesc(e.target.value)} />
          </div>
        </>
      )
    }

    if (type === 'Transfer') {
      return (
        <>
          <div className="form-group">
            <label className="form-label">Tarih</label>
            <input type="date" className="form-input" value={transferDate} onChange={(e) => setTransferDate(e.target.value)} />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Gönderen</label>
              <select className="form-input" value={fromAccount} onChange={(e) => setFromAccount(e.target.value)}>
                <option value="">Seçiniz</option>
                <AccountOptions accounts={accounts} types={['Banka', 'Kredi Kartı', 'Nakit']} />
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Alıcı</label>
              <select className="form-input" value={toAccount} onChange={(e) => setToAccount(e.target.value)}>
                <option value="">Seçiniz</option>
                <AccountOptions accounts={accounts} types={['Banka', 'Kredi Kartı', 'Nakit']} />
              </select>
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">Tutar (₺)</label>
            <input type="number" min="0" step="0.01" className="form-input" value={transferAmount} onChange={(e) => setTransferAmount(e.target.value)} />
          </div>
          <div className="form-group">
            <label className="form-label">Açıklama</label>
            <textarea className="form-input textarea-field" rows={2} value={transferDesc} onChange={(e) => setTransferDesc(e.target.value)} />
          </div>
        </>
      )
    }

    if (type === 'Borçlanma') {
      return (
        <>
          <div className="form-group">
            <label className="form-label">Borçlanılan Kişi / Firma</label>
            <input type="text" className="form-input" value={debtContact} onChange={(e) => setDebtContact(e.target.value)} placeholder="Tedarikçi / taşeron adı" />
          </div>
          <div className="form-group">
            <label className="form-label">Proje (opsiyonel)</label>
            <select className="form-input" value={debtProject} onChange={(e) => setDebtProject(e.target.value)}>
              <option value="">Proje seçilmedi</option>
              {projects.map((p) => <option key={p.id} value={p.name}>{p.name}</option>)}
            </select>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Tutar (₺)</label>
              <input type="number" min="0" step="0.01" className="form-input" value={debtAmount} onChange={(e) => setDebtAmount(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Vade Tarihi</label>
              <input type="date" className="form-input" value={debtDueDate} onChange={(e) => setDebtDueDate(e.target.value)} />
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">Açıklama (opsiyonel)</label>
            <textarea className="form-input textarea-field" rows={2} value={debtDesc} onChange={(e) => setDebtDesc(e.target.value)} />
          </div>
        </>
      )
    }

    if (type === 'Kredi Kullanımı') {
      return (
        <>
          <div className="form-group">
            <label className="form-label">Tarih</label>
            <input type="date" className="form-input" value={krediDate} onChange={(e) => setKrediDate(e.target.value)} />
          </div>
          <div className="form-group">
            <label className="form-label">Banka</label>
            <select className="form-input" value={krediBank} onChange={(e) => setKrediBank(e.target.value)}>
              <option value="">Seçiniz</option>
              <AccountOptions accounts={accounts} types={['Banka']} />
            </select>
          </div>
          <div className="form-group">
            <label className="form-label">Proje (opsiyonel)</label>
            <select className="form-input" value={krediProject} onChange={(e) => setKrediProject(e.target.value)}>
              <option value="">Proje seçilmedi</option>
              {projects.map((p) => <option key={p.id} value={p.name}>{p.name}</option>)}
            </select>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Tutar (₺)</label>
              <input type="number" min="0" step="0.01" className="form-input" value={krediAmount} onChange={(e) => setKrediAmount(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Vade (Ay)</label>
              <input type="number" className="form-input" placeholder="12" value={krediTermMonths} onChange={(e) => setKrediTermMonths(e.target.value)} />
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">Açıklama</label>
            <textarea className="form-input textarea-field" rows={2} value={krediDesc} onChange={(e) => setKrediDesc(e.target.value)} />
          </div>
        </>
      )
    }

    if (type === 'Satış') {
      return (
        <>
          <div className="form-group">
            <label className="form-label">Tarih</label>
            <input type="date" className="form-input" value={satisDate} onChange={(e) => setSatisDate(e.target.value)} />
          </div>
          <div className="form-group">
            <label className="form-label">Proje</label>
            <select className="form-input" value={satisProject} onChange={(e) => setSatisProject(e.target.value)}>
              <option value="">Proje seçilmedi</option>
              {projects.map((p) => <option key={p.id} value={p.name}>{p.name}</option>)}
            </select>
          </div>
          <div className="form-group">
            <label className="form-label">Müşteri</label>
            <input type="text" className="form-input" value={satisCustomer} onChange={(e) => setSatisCustomer(e.target.value)} placeholder="Müşteri Adı Soyadı" />
          </div>
          <div className="form-group">
            <label className="form-label">Bölüm / Daire</label>
            <input type="text" className="form-input" value={satisUnit} onChange={(e) => setSatisUnit(e.target.value)} placeholder="A Blok No: 12" />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Satış Bedeli (₺)</label>
              <input type="number" min="0" step="0.01" className="form-input" value={satisPrice} onChange={(e) => setSatisPrice(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Peşinat (₺)</label>
              <input type="number" min="0" step="0.01" className="form-input" value={satisDownPayment} onChange={(e) => setSatisDownPayment(e.target.value)} />
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">Açıklama</label>
            <textarea className="form-input textarea-field" rows={2} value={satisDesc} onChange={(e) => setSatisDesc(e.target.value)} />
          </div>
        </>
      )
    }

    return null
  }

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 560 }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">Yeni {type}</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            {renderFields()}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-ghost" onClick={onClose} disabled={saving}>Vazgeç</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving}>
              {saving ? <><span className="loader" /> Kaydediliyor...</> : 'Kaydet'}
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body,
  )
}
