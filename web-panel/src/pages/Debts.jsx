import { useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { useNavigate } from 'react-router-dom'
import {
  Receipt, Wallet, HardHat, Plus, ChevronRight, ChevronDown, X, Trash2, Link2, FileText,
} from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num, parseMoneyInput, formatAmountForDisplay } from '../utils'
import LoanFormModal from '../components/LoanFormModal'
import ChequeFormModal from '../components/ChequeFormModal'
import MoneyInput from '../components/MoneyInput'

function NewDebtModal({ projects, categories = [], onClose, onSave, onAddCategory }) {
  const [amount, setAmount] = useState('')
  const [contactName, setContactName] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [projectId, setProjectId] = useState('')
  const [category, setCategory] = useState('')
  const [description, setDescription] = useState('')
  const [invoiceFile, setInvoiceFile] = useState(null)
  const invoiceFileRef = useRef(null)
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')
  const [expandedGroups, setExpandedGroups] = useState({})
  const [catSearch, setCatSearch] = useState('')
  const [addingCategory, setAddingCategory] = useState(false)
  const [newCatName, setNewCatName] = useState('')
  const [newCatGroup, setNewCatGroup] = useState('')
  const [catSaving, setCatSaving] = useState(false)

  const mainCategories = useMemo(
    () => (categories || []).filter((c) => !c.parent && c.type === 'cost'),
    [categories],
  )

  const filteredGroupedCategories = useMemo(() => {
    const groups = {}
    const query = catSearch.trim().toLowerCase()
    for (const c of mainCategories) {
      const matchesMain = c.name.toLowerCase().includes(query)
      const matchesGroup = (c.group || 'Diğer').toLowerCase().includes(query)
      if (!query || matchesMain || matchesGroup) {
        const g = c.group || 'Diğer'
        if (!groups[g]) groups[g] = []
        groups[g].push(c)
      }
    }
    return groups
  }, [mainCategories, catSearch])

  const toggleGroup = (groupName) => {
    setExpandedGroups((prev) => ({ ...prev, [groupName]: !prev[groupName] }))
  }

  const handleAddCategory = async () => {
    const name = newCatName.trim()
    if (!name || !onAddCategory) return
    setCatSaving(true)
    try {
      await onAddCategory({
        name,
        type: 'cost',
        group: newCatGroup.trim() || 'Diğer',
        parent: null,
      })
      setCategory(name)
      setNewCatName('')
      setNewCatGroup('')
      setAddingCategory(false)
    } catch {
      setErr('Kategori eklenemedi.')
    } finally {
      setCatSaving(false)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (parseMoneyInput(amount) <= 0) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onSave({
        amount: parseMoneyInput(amount),
        contactName,
        dueDate,
        projectId: projectId ? Number(projectId) : null,
        category: category || 'Borçlanma',
        description,
        invoiceFile,
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
          <span className="modal-title">Yeni Borçlanma</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}

            <div className="input-group">
              <label className="input-label">Tutar (₺)</label>
              <MoneyInput className="input-field" value={amount} onChange={setAmount} placeholder="0" autoFocus />
            </div>

            <div className="input-group">
              <label className="input-label">Borçlanılan Kişi / Firma</label>
              <input className="input-field" type="text" value={contactName}
                onChange={(e) => setContactName(e.target.value)} placeholder="Tedarikçi / taşeron adı" />
            </div>

            <div className="input-group">
              <label className="input-label">Vade Tarihi</label>
              <input className="input-field" type="date" value={dueDate}
                onChange={(e) => setDueDate(e.target.value)} />
            </div>


            <div className="input-group">
              <label className="input-label">Fatura Görseli (opsiyonel)</label>
              <input
                ref={invoiceFileRef}
                type="file"
                accept="image/*,.pdf"
                hidden
                onChange={(e) => setInvoiceFile(e.target.files?.[0] || null)}
              />
              {invoiceFile ? (
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                  {/\.(png|jpe?g|gif|webp|bmp)$/i.test(invoiceFile.name) ? (
                    <img src={URL.createObjectURL(invoiceFile)} alt="" style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover' }} />
                  ) : (
                    <FileText size={20} className="text-primary" />
                  )}
                  <span style={{ fontSize: '0.85rem', flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{invoiceFile.name}</span>
                  <button type="button" className="icon-btn" onClick={() => setInvoiceFile(null)} title="Kaldır">
                    <X size={16} />
                  </button>
                </div>
              ) : (
                <button type="button" className="btn-secondary" style={{ width: 'auto', marginTop: 0 }} onClick={() => invoiceFileRef.current?.click()}>
                  <Link2 size={16} /> Dosya Seç
                </button>
              )}
            </div>

            <div className="input-group">
              <label className="input-label">Proje (opsiyonel)</label>
              <select className="input-field" value={projectId} onChange={(e) => setProjectId(e.target.value)}>
                <option value="">Proje seçilmedi</option>
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
            </div>

            <div className="input-group">
              <label className="input-label">Kategori Seçimi</label>

              {addingCategory ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', padding: '0.75rem', border: '1px solid var(--color-accent)', borderRadius: '8px', marginBottom: '0.5rem', backgroundColor: 'var(--color-surface-variant)' }}>
                  <div style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--color-accent)' }}>Yeni Kategori</div>
                  <input
                    type="text"
                    className="input-field"
                    autoFocus
                    placeholder="Kategori adı (örn. Taşımacılık)"
                    style={{ height: '36px', fontSize: '0.85rem' }}
                    value={newCatName}
                    onChange={(e) => setNewCatName(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddCategory() } }}
                  />
                  <input
                    type="text"
                    className="input-field"
                    placeholder="Grup adı (opsiyonel, örn. Hane)"
                    style={{ height: '36px', fontSize: '0.85rem' }}
                    value={newCatGroup}
                    onChange={(e) => setNewCatGroup(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddCategory() } }}
                  />
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <button type="button" className="btn-secondary" style={{ flex: 1, marginTop: 0, padding: '0.4rem' }}
                      onClick={() => { setAddingCategory(false); setNewCatName(''); setNewCatGroup('') }}>
                      İptal
                    </button>
                    <button type="button" className="btn-primary" style={{ flex: 1, marginTop: 0, padding: '0.4rem' }}
                      disabled={catSaving || !newCatName.trim()}
                      onClick={handleAddCategory}>
                      {catSaving ? <span className="loader" /> : 'Ekle'}
                    </button>
                  </div>
                </div>
              ) : (
                <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '0.5rem', alignItems: 'center' }}>
                  <input
                    type="text"
                    className="input-field"
                    style={{ flex: 1, height: '36px', fontSize: '0.85rem', marginBottom: 0 }}
                    placeholder="Kategori ara..."
                    value={catSearch}
                    onChange={(e) => setCatSearch(e.target.value)}
                  />
                  <button type="button" className="btn-secondary"
                    style={{ width: 'auto', marginTop: 0, padding: '0 0.75rem', height: '36px', whiteSpace: 'nowrap', fontSize: '0.82rem' }}
                    onClick={() => setAddingCategory(true)}>
                    + Kategori
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
                    const selectedCat = cats.find((c) => c.name === category)

                    return (
                      <div key={groupName} style={{ display: 'flex', flexDirection: 'column' }}>
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

                        {isExpanded && (
                          <div style={{
                            display: 'flex',
                            flexWrap: 'wrap',
                            gap: '0.35rem',
                            padding: '0.4rem 0.4rem 0.4rem 1.2rem',
                            animation: 'fadeIn 0.15s ease'
                          }}>
                            {cats.map((c) => {
                              const isSelected = c.name === category
                              return (
                                <button
                                  key={c.id}
                                  type="button"
                                  onClick={() => setCategory(isSelected ? '' : c.name)}
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

            <div className="input-group">
              <label className="input-label">Açıklama (opsiyonel)</label>
              <textarea className="input-field textarea-field" rows={2} value={description}
                onChange={(e) => setDescription(e.target.value)} placeholder="Not..." />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-ghost" onClick={onClose} disabled={saving}>Vazgeç</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving}>
              {saving ? <><span className="loader" /> Kaydediliyor...</> : 'Borçlanmayı Kaydet'}
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body
  )
}

function PayDebtModal({ kind, target, accounts, onClose, onPay }) {
  const [amount, setAmount] = useState(target.amount > 0 ? formatAmountForDisplay(target.amount) : '')
  const [accountId, setAccountId] = useState(accounts[0]?.id || '')
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (parseMoneyInput(amount) <= 0) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onPay({ kind, ref: target.ref, amount: parseMoneyInput(amount), fromAccountId: accountId ? Number(accountId) : null })
      onClose()
    } catch {
      setErr('Ödeme kaydedilemedi. Lütfen tekrar deneyin.')
    } finally {
      setSaving(false)
    }
  }

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">Öde</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div style={{ marginBottom: '1rem', color: 'var(--color-text-muted)', fontSize: '0.9rem' }}>
              {target.name} — Kalan: <strong>{formatCurrency(target.amount)}</strong>
            </div>
            <div className="input-group">
              <label className="input-label">Ödenen Tutar (₺)</label>
              <MoneyInput className="input-field" value={amount} onChange={setAmount} autoFocus />
            </div>
            <div className="input-group">
              <label className="input-label">Hesap</label>
              {accounts.length === 0 ? (
                <div className="error-message">Önce bir Banka/Nakit hesabı ekleyin.</div>
              ) : (
                <select className="input-field" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                  {accounts.map((a) => (
                    <option key={a.id} value={a.id}>{a.name} hesabından</option>
                  ))}
                </select>
              )}
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-ghost" onClick={onClose} disabled={saving}>Vazgeç</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving || accounts.length === 0}>
              {saving ? <span className="loader" /> : 'Öde'}
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body
  )
}

function DebtSection({ title, items, icon: Icon, onNew, onItemClick, onDelete, onPay }) {
  return (
    <div>
      <div className="section-header">
        <span className="section-title">{title}</span>
        {onNew && (
          <button className="btn-inline-text" onClick={onNew}>
            <Plus size={16} /> Yeni İşlem
          </button>
        )}
      </div>
      <div className="list-group">
        {items.length === 0 ? (
          <div className="debt-empty">Kayıt bulunamadı.</div>
        ) : (
          items.map((it, i) => (
            <div
              className="list-item"
              key={it.ref?.id ?? i}
              onClick={() => onItemClick && it.ref && onItemClick(it.ref)}
              style={{ cursor: onItemClick && it.ref ? 'pointer' : 'default' }}
            >
              <div className="list-icon-box"><Icon size={20} className="text-primary" /></div>
              <div className="list-item-content">
                <div className="list-item-title">{it.name}</div>
              </div>
              <div className="list-item-value">{formatCurrency(it.amount)}</div>
              {onPay && it.ref && (
                <button
                  className="btn-inline-text"
                  style={{ fontSize: '0.8rem', marginLeft: '0.5rem' }}
                  onClick={(e) => { e.stopPropagation(); onPay(it) }}
                >
                  Öde
                </button>
              )}
              {onDelete && it.ref ? (
                <button
                  className="icon-btn"
                  style={{ color: 'var(--color-danger)', marginLeft: '0.5rem' }}
                  onClick={(e) => { e.stopPropagation(); onDelete(it.ref) }}
                  title="Sil"
                >
                  <Trash2 size={16} />
                </button>
              ) : (
                <ChevronRight size={14} className="text-muted" style={{ marginLeft: '0.75rem' }} />
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}

export default function Debts() {
  const navigate = useNavigate()
  const {
    loans, accounts, cheques, contacts, projects, categories, addDebt, addCategory,
    addLoan, updateLoan, deleteLoan, addCheque, updateCheque, deleteCheque,
    payDebt, loading, loaded,
  } = useData()
  const [modalOpen, setModalOpen] = useState(false)
  const [loanTarget, setLoanTarget] = useState(undefined) // undefined=closed, null=create, object=edit
  const [chequeTarget, setChequeTarget] = useState(undefined)
  const [payTarget, setPayTarget] = useState(null) // { kind, item }

  const payAccounts = useMemo(
    () => accounts.filter((a) => a.type === 'Banka' || a.type === 'Nakit'),
    [accounts],
  )

  const handleDeleteLoan = async (loan) => {
    if (!window.confirm(`"${loan.name}" kredisini silmek istediğinize emin misiniz?`)) return
    try {
      await deleteLoan(loan.id)
    } catch {
      alert('Kredi silinemedi.')
    }
  }

  const handleDeleteCheque = async (cheque) => {
    if (!window.confirm('Bu çeki silmek istediğinize emin misiniz?')) return
    try {
      await deleteCheque(cheque.id)
    } catch {
      alert('Çek silinemedi.')
    }
  }

  const handleSaveLoan = async (body) => {
    if (loanTarget && loanTarget.id) {
      await updateLoan(loanTarget.id, body)
    } else {
      await addLoan(body)
    }
  }

  const handleSaveCheque = async (body) => {
    if (chequeTarget && chequeTarget.id) {
      await updateCheque(chequeTarget.id, body)
    } else {
      await addCheque(body)
    }
  }

  const bankaBorclari = useMemo(() => {
    const arr = loans.map((l) => ({ name: l.name, amount: num(l.remaining), ref: l }))
    accounts
      .filter((a) => (a.type === 'BCH' || a.type === 'Kredi Kartı') && num(a.balance) < 0)
      .forEach((a) => arr.push({ name: `${a.name} (kullanılan)`, amount: Math.abs(num(a.balance)) }))
    return arr
  }, [loans, accounts])

  const ticariBorclar = useMemo(
    () => contacts
      .filter((c) => (c.kind === 'supplier' || c.kind === 'subcontractor') && num(c.balance) > 0)
      .map((c) => ({ name: c.name, amount: num(c.balance), ref: c })),
    [contacts],
  )

  const cekler = useMemo(
    () => cheques
      .filter((c) => c.direction === 'issued' && c.status !== 'cashed')
      .map((c) => ({ name: c.bank_name ? `${c.bank_name} çeki` : 'Çek', amount: num(c.amount), ref: c })),
    [cheques],
  )

  const total = useMemo(() => {
    const sum = (arr) => arr.reduce((s, i) => s + i.amount, 0)
    return sum(bankaBorclari) + sum(ticariBorclar) + sum(cekler)
  }, [bankaBorclari, ticariBorclar, cekler])

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  return (
    <div>
      {/* Toplam Borç kartı */}
      <div className="debt-total-card">
        <div>
          <div className="total-card-label">TOPLAM BORÇ</div>
          <div className="total-card-value">{formatCurrency(total)}</div>
        </div>
        <div className="debt-total-icon"><Receipt size={40} /></div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', marginTop: '1.75rem' }}>
        <DebtSection
          title="BANKA BORÇLARI"
          items={bankaBorclari}
          icon={Wallet}
          onNew={() => setLoanTarget(null)}
          onItemClick={(loan) => setLoanTarget(loan)}
          onDelete={handleDeleteLoan}
          onPay={(it) => setPayTarget({ kind: 'loan', item: it })}
        />
        <DebtSection
          title="TİCARİ BORÇLAR"
          items={ticariBorclar}
          icon={HardHat}
          onNew={() => setModalOpen(true)}
          onItemClick={(contact) => navigate(`/dashboard/contacts/${contact.id}`)}
          onPay={(it) => setPayTarget({ kind: 'contact', item: it })}
        />
        <DebtSection
          title="ÇEKLER"
          items={cekler}
          icon={Receipt}
          onNew={() => setChequeTarget(null)}
          onItemClick={(cheque) => setChequeTarget(cheque)}
          onDelete={handleDeleteCheque}
          onPay={(it) => setPayTarget({ kind: 'cheque', item: it })}
        />
      </div>

      {payTarget && (
        <PayDebtModal
          kind={payTarget.kind}
          target={payTarget.item}
          accounts={payAccounts}
          onClose={() => setPayTarget(null)}
          onPay={payDebt}
        />
      )}

      {modalOpen && (
        <NewDebtModal
          projects={projects}
          categories={categories}
          onClose={() => setModalOpen(false)}
          onSave={addDebt}
          onAddCategory={addCategory}
        />
      )}

      {loanTarget !== undefined && (
        <LoanFormModal
          loan={loanTarget}
          onClose={() => setLoanTarget(undefined)}
          onSave={handleSaveLoan}
        />
      )}

      {chequeTarget !== undefined && (
        <ChequeFormModal
          cheque={chequeTarget}
          contacts={contacts}
          onClose={() => setChequeTarget(undefined)}
          onSave={handleSaveCheque}
        />
      )}
    </div>
  )
}
