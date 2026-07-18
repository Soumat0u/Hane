import { useMemo, useState, useEffect, useRef } from 'react'
import { createPortal } from 'react-dom'
import { X, Link2, FileText, ChevronDown, ChevronRight } from 'lucide-react'
import { useData } from '../context/DataContext'
import { num, parseMoneyInput, formatAmountForDisplay } from '../utils'
import MoneyInput from './MoneyInput'

const isImageFile = (url) => /\.(png|jpe?g|gif|webp|bmp|svg)$/i.test(url || '')

const today = () => new Date().toISOString().slice(0, 10)

const getMonthBounds = () => {
  const now = new Date()
  const y = now.getFullYear()
  const m = now.getMonth()
  const firstDay = `${y}-${String(m + 1).padStart(2, '0')}-01`
  const lastDayDate = new Date(y, m + 1, 0)
  const lastDay = `${y}-${String(m + 1).padStart(2, '0')}-${String(lastDayDate.getDate()).padStart(2, '0')}`
  return { min: firstDay, max: lastDay }
}

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

const UNITS = ['Adet', 'Ton', 'Kg', 'Metre', 'm²', 'm³', 'Litre', 'Saat', 'Ay', 'Gün', 'Yıl', 'Paket', 'Kutu', 'Diğer']

/**
 * Mobildeki `YeniIslemScreen`'in web karşılığı: sol panelden seçilen türe göre
 * (Ödeme, Transfer, Borçlanma, Kredi Kullanımı, Satış) doğru formu gösterir.
 */
export default function NewTransactionFormModal({ type: rawType, onClose, initialProjectId = null, initialTransaction = null }) {
  const type = initialTransaction?.type === 'Gelir' || initialTransaction?.type === 'Gider' || initialTransaction?.type === 'Tahsilat'
    ? 'Ödeme'
    : (rawType === 'Borç' ? 'Borçlanma' : (initialTransaction?.type || rawType))
    
  const {
    projects, accounts, categories, addTransaction, addTransactionWithAttachment,
    updateTransaction, updateTransactionWithAttachment, addLoan, addDebt, addCategory,
  } = useData()
  const bounds = useMemo(getMonthBounds, [])
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')
  const initialProjectName = useMemo(
    () => (initialProjectId != null ? projects.find((p) => String(p.id) === String(initialProjectId))?.name || '' : ''),
    [initialProjectId, projects],
  )

  // --- Ödeme (Gelir/Gider — Tahsilat da bu formun gelir tarafıdır) ---
  const [isIncome, setIsIncome] = useState(false)
  const [odemeDate, setOdemeDate] = useState(today())
  const [odemeProject, setOdemeProject] = useState(initialProjectName)
  const [mainCategory, setMainCategory] = useState('')
  const [subCategory, setSubCategory] = useState('')
  const [odemeAccount, setOdemeAccount] = useState('')
  const [counterparty, setCounterparty] = useState('')
  const [odemeAmount, setOdemeAmount] = useState('')
  const [quantity, setQuantity] = useState('')
  const [unit, setUnit] = useState('')
  const [odemeDesc, setOdemeDesc] = useState('')
  const [pickedAttachment, setPickedAttachment] = useState(null) // File
  const [removeExistingAttachment, setRemoveExistingAttachment] = useState(false)
  const attachmentInputRef = useRef(null)

  const mainCategories = useMemo(
    () => categories.filter((c) => !c.parent && (isIncome ? c.type === 'income' : c.type === 'cost')),
    [categories, isIncome],
  )
  const mainCategoryObj = useMemo(
    () => mainCategories.find((c) => c.name === mainCategory) || null,
    [mainCategories, mainCategory],
  )
  const subCategories = useMemo(
    () => (mainCategoryObj ? categories.filter((c) => c.parent === mainCategoryObj.id) : []),
    [categories, mainCategoryObj],
  )

  // Ana kategori seçiliyken listede olmayan yeni bir alt kategori eklenebilir.
  const [addingSubCategory, setAddingSubCategory] = useState(false)
  const [expandedGroups, setExpandedGroups] = useState({})
  const [catSearch, setCatSearch] = useState('')

  // Yeni ana kategori ekleme
  const [addingMainCategory, setAddingMainCategory] = useState(false)
  const [newMainCategoryName, setNewMainCategoryName] = useState('')
  const [newMainCategoryGroup, setNewMainCategoryGroup] = useState('')
  const [mainCategorySaving, setMainCategorySaving] = useState(false)

  const handleAddMainCategory = async () => {
    const name = newMainCategoryName.trim()
    if (!name) return
    setMainCategorySaving(true)
    try {
      await addCategory({
        name,
        type: isIncome ? 'income' : 'cost',
        group: newMainCategoryGroup.trim() || 'Diğer',
        parent: null,
      })
      setMainCategory(name)
      setNewMainCategoryName('')
      setNewMainCategoryGroup('')
      setAddingMainCategory(false)
    } catch {
      setErr('Ana kategori eklenemedi.')
    } finally {
      setMainCategorySaving(false)
    }
  }

  const filteredGroupedCategories = useMemo(() => {
    const groups = {}
    const query = catSearch.trim().toLowerCase()
    for (const c of mainCategories) {
      const subCats = categories.filter((sc) => sc.parent === c.id)
      const matchesMain = c.name.toLowerCase().includes(query)
      const matchesGroup = (c.group || 'Diğer').toLowerCase().includes(query)
      const matchesSub = subCats.some((sc) => sc.name.toLowerCase().includes(query))
      
      if (!query || matchesMain || matchesGroup || matchesSub) {
        const g = c.group || 'Diğer'
        if (!groups[g]) groups[g] = []
        groups[g].push(c)
      }
    }
    return groups
  }, [mainCategories, categories, catSearch])

  const toggleGroup = (groupName) => {
    setExpandedGroups((prev) => ({
      ...prev,
      [groupName]: !prev[groupName],
    }))
  }

  // Reset expanded groups and selection on type toggle
  useEffect(() => {
    setExpandedGroups({})
  }, [isIncome])
  const [newSubCategoryName, setNewSubCategoryName] = useState('')
  const [subCategorySaving, setSubCategorySaving] = useState(false)

  const handleAddSubCategory = async () => {
    const name = newSubCategoryName.trim()
    if (!name || !mainCategoryObj) return
    setSubCategorySaving(true)
    try {
      const created = await addCategory({
        name,
        type: isIncome ? 'income' : 'cost',
        parent: mainCategoryObj.id,
      })
      setSubCategory(created.name)
      setNewSubCategoryName('')
      setAddingSubCategory(false)
    } catch {
      setErr('Alt kategori eklenemedi.')
    } finally {
      setSubCategorySaving(false)
    }
  }

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

  const initializedRef = useRef(false)

  // Effect for edit mode
  useEffect(() => {
    if (initialTransaction && !initializedRef.current && categories.length > 0 && projects.length > 0) {
      initializedRef.current = true
      const t = initialTransaction
      const dateStr = (t.date || '').slice(0, 10)
      const amtStr = formatAmountForDisplay(t.amount)
      
      if (type === 'Ödeme') {
        setIsIncome(t.type === 'Gelir' || t.type === 'Tahsilat')
        setOdemeDate(dateStr)
        const p = projects.find(x => x.id === t.project_id)
        if (p) setOdemeProject(p.name)
        setOdemeAmount(amtStr)
        setOdemeDesc(t.description || '')
        setCounterparty(t.contact_name || '')
        setQuantity(t.quantity != null ? String(t.quantity) : '')
        setUnit(t.unit || '')
        setOdemeAccount(t.source_name || t.dest_name || '')
        
        // Kategori adları cost/income türleri arasında çakışabildiği için (örn. iki ayrı
        // "Diğer") aramayı işlemin gerçek türüne (Gelir/Tahsilat -> income, Gider -> cost)
        // ait kategorilerle sınırlıyoruz — yoksa yanlış (türü uyuşmayan) bir ana kategori
        // eşleşir ve Alt Kategori listesi boş kalıp devre dışı görünür.
        const wantIncome = t.type === 'Gelir' || t.type === 'Tahsilat'
        const domainCats = categories.filter(c => wantIncome ? c.type === 'income' : c.type === 'cost')
        let mainCat = ''
        let subCat = ''
        const parentCat = domainCats.find(c => c.name === t.category && !c.parent)
        if (parentCat) {
          mainCat = parentCat.name
        } else {
          const childCat = domainCats.find(c => c.name === t.category && c.parent)
          if (childCat) {
            const pCat = domainCats.find(c => c.id === childCat.parent)
            if (pCat) {
              mainCat = pCat.name
              subCat = childCat.name
            }
          } else {
            mainCat = t.category || ''
          }
        }
        setMainCategory(mainCat)
        setSubCategory(subCat)
      } else if (type === 'Transfer') {
        setTransferDate(dateStr)
        setFromAccount(t.source_name || '')
        setToAccount(t.dest_name || '')
        setTransferAmount(amtStr)
        setTransferDesc(t.description || '')
      } else if (type === 'Borçlanma') {
        setDebtContact(t.contact_name || '')
        setDebtAmount(amtStr)
        if (t.due_date) setDebtDueDate((t.due_date || '').slice(0, 10))
        const p = projects.find(x => x.id === t.project_id)
        if (p) setDebtProject(p.name)
        setDebtDesc(t.description || '')
      } else if (type === 'Kredi Kullanımı') {
        setKrediDate(dateStr)
        setKrediBank(t.source_name || '')
        const p = projects.find(x => x.id === t.project_id)
        if (p) setKrediProject(p.name)
        setKrediAmount(amtStr)
        setKrediDesc(t.description || '')
      } else if (type === 'Satış') {
        setSatisDate(dateStr)
        const p = projects.find(x => x.id === t.project_id)
        if (p) setSatisProject(p.name)
        setSatisCustomer(t.contact_name || '')
        setSatisPrice(amtStr)
        // Description might contain "A Blok No: 12 • Peşinat: ₺1000 • Actual desc"
        // We will just put the whole thing in satisDesc for edit simplicity
        setSatisDesc(t.description || '')
      }
    }
  }, [initialTransaction, categories, projects, type])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErr('')
    setSaving(true)
    try {
      if (type === 'Ödeme') {
        if (parseMoneyInput(odemeAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        if (!isIncome) {
          const selectedAcc = accounts.find((a) => a.name === odemeAccount)
          if (selectedAcc) {
            const limit = ['Kredi Kartı', 'BCH', 'Esnek'].includes(selectedAcc.type)
              ? num(selectedAcc.available_limit)
              : num(selectedAcc.balance)
            if (parseMoneyInput(odemeAmount) > limit) {
              throw new Error('Yetersiz bakiye veya limit! İşlem tutarı mevcut bakiyeden/limitten büyük olamaz.')
            }
          }
        }
        const data = {
          project_id: projectIdByName(odemeProject),
          type: isIncome ? 'Gelir' : 'Gider',
          category: subCategory || mainCategory || '',
          amount: parseMoneyInput(odemeAmount),
          date: odemeDate,
          source_name: odemeAccount,
          dest_name: '',
          contact_name: counterparty,
          description: odemeDesc,
          quantity: quantity ? num(quantity) : null,
          unit,
        }
        if (initialTransaction) {
          if (pickedAttachment) {
            await updateTransactionWithAttachment(initialTransaction.id, data, pickedAttachment)
          } else if (removeExistingAttachment) {
            await updateTransaction(initialTransaction.id, { ...data, attachment: null })
          } else {
            await updateTransaction(initialTransaction.id, data)
          }
        } else if (pickedAttachment) {
          await addTransactionWithAttachment(data, pickedAttachment)
        } else {
          await addTransaction(data)
        }
      } else if (type === 'Transfer') {
        if (parseMoneyInput(transferAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        const data = {
          type: 'Transfer',
          category: 'Transfer',
          amount: parseMoneyInput(transferAmount),
          date: transferDate,
          source_name: fromAccount,
          dest_name: toAccount,
          description: transferDesc,
        }
        if (initialTransaction) await updateTransaction(initialTransaction.id, data)
        else await addTransaction(data)
      } else if (type === 'Borçlanma') {
        if (parseMoneyInput(debtAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        if (initialTransaction) {
          await updateTransaction(initialTransaction.id, {
            project_id: projectIdByName(debtProject),
            amount: parseMoneyInput(debtAmount),
            contact_name: debtContact,
            due_date: debtDueDate,
            description: debtDesc,
          })
        } else {
          await addDebt({
            amount: parseMoneyInput(debtAmount),
            contactName: debtContact,
            dueDate: debtDueDate,
            projectId: projectIdByName(debtProject),
            description: debtDesc,
          })
        }
      } else if (type === 'Kredi Kullanımı') {
        if (parseMoneyInput(krediAmount) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        const data = {
          project_id: projectIdByName(krediProject),
          type: 'Kredi Kullanımı',
          category: 'Kredi Kullanımı',
          amount: parseMoneyInput(krediAmount),
          date: krediDate,
          source_name: krediBank,
          description: krediDesc,
        }
        if (initialTransaction) {
          await updateTransaction(initialTransaction.id, data)
        } else {
          await addTransaction(data)
          await addLoan({
            name: `${krediBank} Kredisi`,
            kind: 'loan',
            bank_name: krediBank,
            principal: parseMoneyInput(krediAmount),
            total_payable: parseMoneyInput(krediAmount),
            term_months: krediTermMonths ? Number(krediTermMonths) : 0,
            start_date: krediDate,
          })
        }
      } else if (type === 'Satış') {
        if (parseMoneyInput(satisPrice) <= 0) throw new Error('Lütfen geçerli bir tutar girin.')
        const extras = [satisUnit, satisDownPayment ? `Peşinat: ₺${satisDownPayment}` : ''].filter(Boolean).join(' • ')
        const data = {
          project_id: projectIdByName(satisProject),
          type: 'Satış',
          category: 'Satış',
          amount: parseMoneyInput(satisPrice),
          date: satisDate,
          contact_name: satisCustomer,
          description: extras ? `${extras}${satisDesc ? ' • ' + satisDesc : ''}` : satisDesc,
        }
        if (initialTransaction) await updateTransaction(initialTransaction.id, data)
        else await addTransaction(data)
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
            <input type="date" className="form-input" min={bounds.min} max={bounds.max} value={odemeDate} onChange={(e) => setOdemeDate(e.target.value)} />
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

          <div className="form-group">
            <label className="form-label">{isIncome ? 'Tahsilat Hesabı' : 'Ödeme Kaynağı'}</label>
            <select className="form-input" value={odemeAccount} onChange={(e) => setOdemeAccount(e.target.value)}>
              <option value="">Seçiniz</option>
              <AccountOptions accounts={accounts} types={['Banka', 'Kredi Kartı', 'Nakit']} />
            </select>
          </div>

          {/* Ana ve Alt Kategori Seçimi */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Ana Kategori Seçimi</label>
              
              {addingMainCategory ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', padding: '0.75rem', border: '1px solid var(--color-accent)', borderRadius: '8px', marginBottom: '0.5rem', backgroundColor: 'var(--color-surface-variant)' }}>
                  <div style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--color-accent)' }}>Yeni Ana Kategori</div>
                  <input
                    type="text"
                    className="form-input"
                    autoFocus
                    placeholder="Kategori adı (örn. Taşımacılık)"
                    style={{ height: '36px', fontSize: '0.85rem' }}
                    value={newMainCategoryName}
                    onChange={(e) => setNewMainCategoryName(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddMainCategory() } }}
                  />
                  <input
                    type="text"
                    className="form-input"
                    placeholder="Grup adı (opsiyonel, örn. Hane)"
                    style={{ height: '36px', fontSize: '0.85rem' }}
                    value={newMainCategoryGroup}
                    onChange={(e) => setNewMainCategoryGroup(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddMainCategory() } }}
                  />
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <button type="button" className="btn-secondary" style={{ flex: 1, marginTop: 0, padding: '0.4rem' }}
                      onClick={() => { setAddingMainCategory(false); setNewMainCategoryName(''); setNewMainCategoryGroup('') }}>
                      İptal
                    </button>
                    <button type="button" className="btn-primary" style={{ flex: 1, marginTop: 0, padding: '0.4rem' }}
                      disabled={mainCategorySaving || !newMainCategoryName.trim()}
                      onClick={handleAddMainCategory}>
                      {mainCategorySaving ? <span className="loader" /> : 'Ekle'}
                    </button>
                  </div>
                </div>
              ) : (
                <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '0.5rem', alignItems: 'center' }}>
                  <input
                    type="text"
                    className="form-input"
                    style={{ flex: 1, height: '36px', fontSize: '0.85rem', marginBottom: 0 }}
                    placeholder="Kategori ara..."
                    value={catSearch}
                    onChange={(e) => setCatSearch(e.target.value)}
                  />
                  <button type="button" className="btn-secondary"
                    style={{ width: 'auto', marginTop: 0, padding: '0 0.75rem', height: '36px', whiteSpace: 'nowrap', fontSize: '0.82rem' }}
                    onClick={() => setAddingMainCategory(true)}>
                    + Ana Kategori
                  </button>
                </div>
              )}
              
              <div style={{
                border: '1px solid var(--color-border)',
                borderRadius: '10px',
                padding: '0.5rem',
                backgroundColor: 'var(--color-surface)',
                maxHeight: '220px',
                overflowY: 'auto',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.25rem'
              }}>
                {Object.keys(filteredGroupedCategories).length === 0 ? (
                  <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)', textAlign: 'center', padding: '1rem' }}>
                    Kategori bulunamadı.
                  </div>
                ) : (
                  Object.entries(filteredGroupedCategories).map(([groupName, cats]) => {
                    const isExpanded = catSearch.trim().length > 0 || !!expandedGroups[groupName]
                    const selectedCat = cats.find((c) => c.name === mainCategory)
                    
                    return (
                      <div key={groupName} style={{ display: 'flex', flexDirection: 'column' }}>
                        {/* Grup Başlığı */}
                        <div 
                          onClick={() => toggleGroup(groupName)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            padding: '0.45rem 0.65rem',
                            borderRadius: '6px',
                            cursor: 'pointer',
                            backgroundColor: selectedCat ? 'rgba(59,130,246,0.08)' : 'transparent',
                            border: selectedCat ? '1px solid rgba(59,130,246,0.25)' : '1px solid transparent',
                            fontWeight: 600,
                            fontSize: '0.82rem',
                            color: selectedCat ? 'var(--color-accent)' : 'var(--color-text-main)',
                            userSelect: 'none',
                            transition: 'all 0.15s ease'
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                            {isExpanded ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
                            <span>{groupName}</span>
                          </div>
                          {selectedCat && !isExpanded && (
                            <span style={{
                              fontSize: '0.72rem',
                              color: 'white',
                              fontWeight: 600,
                              backgroundColor: 'var(--color-accent)',
                              padding: '0.15rem 0.5rem',
                              borderRadius: '20px',
                              maxWidth: '110px',
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap'
                            }}>
                              ✓ {selectedCat.name}
                            </span>
                          )}
                        </div>
                        
                        {/* Grup Elemanları */}
                        {isExpanded && (
                          <div style={{
                            display: 'flex',
                            flexWrap: 'wrap',
                            gap: '0.35rem',
                            padding: '0.4rem 0.4rem 0.4rem 1.2rem',
                            animation: 'fadeIn 0.15s ease'
                          }}>
                            {cats.map((c) => {
                              const isSelected = c.name === mainCategory
                              return (
                                <button
                                  key={c.id}
                                  type="button"
                                  onClick={() => {
                                    setMainCategory(c.name)
                                    setSubCategory('')
                                    setAddingSubCategory(false)
                                    setNewSubCategoryName('')
                                  }}
                                  style={{
                                    padding: '0.3rem 0.75rem',
                                    borderRadius: '20px',
                                    fontSize: '0.8rem',
                                    fontWeight: isSelected ? 700 : 400,
                                    cursor: 'pointer',
                                    backgroundColor: isSelected ? 'var(--color-accent)' : 'var(--color-surface-variant)',
                                    color: isSelected ? '#fff' : 'var(--color-text-main)',
                                    border: `1.5px solid ${isSelected ? 'var(--color-accent)' : 'var(--color-border)'}`,
                                    boxShadow: isSelected ? '0 2px 8px rgba(59,130,246,0.3)' : 'none',
                                    transition: 'all 0.15s ease',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.3rem'
                                  }}
                                >
                                  {isSelected && <span style={{ fontSize: '0.75rem' }}>✓</span>}
                                  {c.name}
                                </button>
                              )
                            })}
                          </div>
                        )}
                      </div>
                    )
                  })
                )}
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Alt Kategori</label>
              {addingSubCategory ? (
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <input
                    type="text"
                    className="form-input"
                    autoFocus
                    placeholder="Yeni alt kategori adı"
                    value={newSubCategoryName}
                    onChange={(e) => setNewSubCategoryName(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddSubCategory() } }}
                  />
                  <button
                    type="button"
                    className="btn-secondary"
                    style={{ width: 'auto', marginTop: 0, padding: '0 0.9rem' }}
                    disabled={subCategorySaving}
                    onClick={() => { setAddingSubCategory(false); setNewSubCategoryName('') }}
                  >
                    İptal
                  </button>
                  <button
                    type="button"
                    className="btn-primary"
                    style={{ width: 'auto', marginTop: 0, padding: '0 0.9rem' }}
                    disabled={subCategorySaving || !newSubCategoryName.trim()}
                    onClick={handleAddSubCategory}
                  >
                    {subCategorySaving ? <span className="loader" /> : 'Ekle'}
                  </button>
                </div>
              ) : (
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <select
                    className="form-input"
                    value={subCategory}
                    onChange={(e) => setSubCategory(e.target.value)}
                    disabled={subCategories.length === 0}
                  >
                    <option value="">Seçiniz (opsiyonel)</option>
                    {subCategories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
                  </select>
                  <button
                    type="button"
                    className="btn-secondary"
                    style={{ width: 'auto', marginTop: 0, padding: '0 0.9rem', whiteSpace: 'nowrap' }}
                    disabled={!mainCategoryObj}
                    title={!mainCategoryObj ? 'Önce ana kategori seçin' : 'Yeni alt kategori ekle'}
                    onClick={() => setAddingSubCategory(true)}
                  >
                    + Yeni
                  </button>
                </div>
              )}
            </div>
          </div>



          <div className="form-group">
            <label className="form-label">{isIncome ? 'Müşteri' : 'Alıcı / Satıcı'}</label>
            <input type="text" className="form-input" value={counterparty} onChange={(e) => setCounterparty(e.target.value)} placeholder={isIncome ? 'Müşteri adı' : 'Betoncu'} />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Tutar (₺)</label>
              <MoneyInput value={odemeAmount} onChange={setOdemeAmount} />
            </div>
            <div className="form-group">
              <label className="form-label">Miktar (opsiyonel)</label>
              <input type="number" className="form-input" value={quantity} onChange={(e) => setQuantity(e.target.value)} />
            </div>
            <div className="form-group">
              <label className="form-label">Birim</label>
              <select className="form-input" value={UNITS.includes(unit) ? unit : (unit ? 'Diğer' : '')} onChange={(e) => setUnit(e.target.value)}>
                <option value="">Seçiniz</option>
                {UNITS.map(u => <option key={u} value={u}>{u}</option>)}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Açıklama</label>
            <textarea className="form-input textarea-field" rows={2} value={odemeDesc} onChange={(e) => setOdemeDesc(e.target.value)} />
          </div>

          <div className="form-group">
            <label className="form-label">Fiş / Fatura</label>
            <input
              ref={attachmentInputRef}
              type="file"
              hidden
              onChange={(e) => {
                const file = e.target.files?.[0] || null
                setPickedAttachment(file)
                if (file) setRemoveExistingAttachment(false)
              }}
            />
            {pickedAttachment ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                {isImageFile(pickedAttachment.name) ? (
                  <img src={URL.createObjectURL(pickedAttachment)} alt="" style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover' }} />
                ) : (
                  <FileText size={20} className="text-primary" />
                )}
                <span style={{ fontSize: '0.85rem', flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{pickedAttachment.name}</span>
                <button type="button" className="icon-btn" onClick={() => setPickedAttachment(null)} title="Kaldır">
                  <X size={16} />
                </button>
              </div>
            ) : !removeExistingAttachment && initialTransaction?.attachment ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                {isImageFile(initialTransaction.attachment) ? (
                  <img src={initialTransaction.attachment} alt="" style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover' }} />
                ) : (
                  <FileText size={20} className="text-primary" />
                )}
                <span style={{ fontSize: '0.85rem', flex: 1 }}>Mevcut ek</span>
                <button type="button" className="icon-btn" onClick={() => setRemoveExistingAttachment(true)} title="Kaldır">
                  <X size={16} />
                </button>
              </div>
            ) : (
              <button type="button" className="btn-secondary" style={{ width: 'auto', marginTop: 0 }} onClick={() => attachmentInputRef.current?.click()}>
                <Link2 size={16} /> Dosya Seç
              </button>
            )}
          </div>
        </>
      )
    }

    if (type === 'Transfer') {
      return (
        <>
          <div className="form-group">
            <label className="form-label">Tarih</label>
            <input type="date" className="form-input" min={bounds.min} max={bounds.max} value={transferDate} onChange={(e) => setTransferDate(e.target.value)} />
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
            <MoneyInput value={transferAmount} onChange={setTransferAmount} />
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
              <MoneyInput value={debtAmount} onChange={setDebtAmount} />
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
            <input type="date" className="form-input" min={bounds.min} max={bounds.max} value={krediDate} onChange={(e) => setKrediDate(e.target.value)} />
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
              <MoneyInput value={krediAmount} onChange={setKrediAmount} />
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
            <input type="date" className="form-input" min={bounds.min} max={bounds.max} value={satisDate} onChange={(e) => setSatisDate(e.target.value)} />
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
              <MoneyInput value={satisPrice} onChange={setSatisPrice} />
            </div>
            <div className="form-group">
              <label className="form-label">Peşinat (₺)</label>
              <MoneyInput value={satisDownPayment} onChange={setSatisDownPayment} />
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
