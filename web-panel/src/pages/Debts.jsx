import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Receipt, Wallet, HardHat, Plus, ChevronRight, X, Trash2,
} from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num, parseMoneyInput, formatAmountForDisplay } from '../utils'
import LoanFormModal from '../components/LoanFormModal'
import ChequeFormModal from '../components/ChequeFormModal'
import MoneyInput from '../components/MoneyInput'

function NewDebtModal({ projects, onClose, onSave }) {
  const [amount, setAmount] = useState('')
  const [contactName, setContactName] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [projectId, setProjectId] = useState('')
  const [description, setDescription] = useState('')
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
      await onSave({
        amount: parseMoneyInput(amount),
        contactName,
        dueDate,
        projectId: projectId ? Number(projectId) : null,
        description,
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
              <label className="input-label">Proje (opsiyonel)</label>
              <select className="input-field" value={projectId} onChange={(e) => setProjectId(e.target.value)}>
                <option value="">Proje seçilmedi</option>
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
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
    </div>
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

  return (
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
    </div>
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
    loans, accounts, cheques, contacts, projects, addDebt,
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
          onClose={() => setModalOpen(false)}
          onSave={addDebt}
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
