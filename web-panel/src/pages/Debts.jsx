import { useMemo, useState } from 'react'
import {
  Receipt, Wallet, HardHat, Plus, ChevronLeft, ChevronRight, X,
} from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'

const isSameDay = (a, b) =>
  !!a && !!b &&
  a.getFullYear() === b.getFullYear() &&
  a.getMonth() === b.getMonth() &&
  a.getDate() === b.getDate()

const parseDate = (s) => {
  if (!s) return null
  const d = new Date(s)
  return Number.isNaN(d.getTime()) ? null : d
}

const fmtDate = (d, raw) =>
  d ? d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' }) : (raw || '-')

const MONTHS = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık']
const WEEKDAYS = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz']

function MiniCalendar({ selectedDay, onSelectDay, paymentDates }) {
  const [focused, setFocused] = useState(() => {
    const d = selectedDay ? new Date(selectedDay) : new Date()
    d.setDate(1)
    return d
  })
  const year = focused.getFullYear()
  const month = focused.getMonth()
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const startOffset = (new Date(year, month, 1).getDay() + 6) % 7 // Pazartesi başlangıç
  const daysInMonth = new Date(year, month + 1, 0).getDate()

  const cells = []
  for (let i = 0; i < startOffset; i++) cells.push(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(d)

  const hasEvent = (d) => paymentDates.some((pd) => isSameDay(pd, d))

  return (
    <div className="calendar">
      <div className="calendar-header">
        <button className="calendar-nav-btn" onClick={() => setFocused(new Date(year, month - 1, 1))} title="Önceki ay">
          <ChevronLeft size={18} />
        </button>
        <span className="calendar-title">{MONTHS[month]} {year}</span>
        <button className="calendar-nav-btn" onClick={() => setFocused(new Date(year, month + 1, 1))} title="Sonraki ay">
          <ChevronRight size={18} />
        </button>
      </div>
      <div className="calendar-grid">
        {WEEKDAYS.map((w) => (
          <span key={w} className="calendar-weekday">{w}</span>
        ))}
        {cells.map((cell, i) => {
          if (cell === null) return <span key={`e${i}`} className="calendar-day empty" />
          const d = new Date(year, month, cell)
          d.setHours(0, 0, 0, 0)
          const classes = ['calendar-day']
          if (isSameDay(d, today)) classes.push('today')
          if (isSameDay(d, selectedDay)) classes.push('selected')
          return (
            <button key={cell} className={classes.join(' ')} onClick={() => onSelectDay(d)}>
              {cell}
              {hasEvent(d) && <span className="calendar-day-marker" />}
            </button>
          )
        })}
      </div>
    </div>
  )
}

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
    if (num(amount) <= 0) {
      setErr('Lütfen geçerli bir tutar girin.')
      return
    }
    setSaving(true)
    setErr('')
    try {
      await onSave({
        amount: num(amount),
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
              <input className="input-field" type="number" min="0" step="0.01" inputMode="decimal"
                value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0" autoFocus />
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

function DebtSection({ title, items, icon: Icon, onNew }) {
  return (
    <div>
      <div className="section-header">
        <span className="section-title">{title}</span>
        <button className="btn-inline-text" onClick={onNew}>
          <Plus size={16} /> Yeni İşlem
        </button>
      </div>
      <div className="list-group">
        {items.length === 0 ? (
          <div className="debt-empty">Kayıt bulunamadı.</div>
        ) : (
          items.map((it, i) => (
            <div className="list-item" key={i}>
              <div className="list-icon-box"><Icon size={20} className="text-primary" /></div>
              <div className="list-item-content">
                <div className="list-item-title">{it.name}</div>
              </div>
              <div className="list-item-value">{formatCurrency(it.amount)}</div>
              <ChevronRight size={14} className="text-muted" style={{ marginLeft: '0.75rem' }} />
            </div>
          ))
        )}
      </div>
    </div>
  )
}

export default function Debts() {
  const { loans, accounts, cheques, contacts, transactions, projects, addDebt, loading, loaded } = useData()
  const [selectedDay, setSelectedDay] = useState(() => {
    const d = new Date()
    d.setHours(0, 0, 0, 0)
    return d
  })
  const [modalOpen, setModalOpen] = useState(false)

  const bankaBorclari = useMemo(() => {
    const arr = loans.map((l) => ({ name: l.name, amount: num(l.remaining) }))
    accounts
      .filter((a) => (a.type === 'BCH' || a.type === 'Kredi Kartı') && num(a.balance) < 0)
      .forEach((a) => arr.push({ name: `${a.name} (kullanılan)`, amount: Math.abs(num(a.balance)) }))
    return arr
  }, [loans, accounts])

  const ticariBorclar = useMemo(
    () => contacts
      .filter((c) => (c.kind === 'supplier' || c.kind === 'subcontractor') && num(c.balance) > 0)
      .map((c) => ({ name: c.name, amount: num(c.balance) })),
    [contacts],
  )

  const cekler = useMemo(
    () => cheques
      .filter((c) => c.direction === 'issued' && c.status !== 'cashed')
      .map((c) => ({ name: c.bank_name ? `${c.bank_name} çeki` : 'Çek', amount: num(c.amount) })),
    [cheques],
  )

  const total = useMemo(() => {
    const sum = (arr) => arr.reduce((s, i) => s + i.amount, 0)
    return sum(bankaBorclari) + sum(ticariBorclar) + sum(cekler)
  }, [bankaBorclari, ticariBorclar, cekler])

  // Vadesi dolan/yaklaşan ÖDEMELER: verilen çekler + vadeli Gider işlemleri.
  const payments = useMemo(() => {
    const list = []
    cheques.forEach((c) => {
      if (c.direction === 'issued' && c.status !== 'cashed') {
        list.push({
          title: c.bank_name ? `${c.bank_name} çeki` : 'Verilen çek',
          amount: num(c.amount),
          date: parseDate(c.due_date),
          rawDate: c.due_date,
        })
      }
    })
    transactions.forEach((t) => {
      if (t.due_date && t.type === 'Gider') {
        list.push({
          title: t.description || t.category || 'Ödeme',
          amount: num(t.amount),
          date: parseDate(t.due_date),
          rawDate: t.due_date,
        })
      }
    })
    list.sort((a, b) => {
      if (!a.date && !b.date) return 0
      if (!a.date) return 1
      if (!b.date) return -1
      return a.date - b.date
    })
    return list
  }, [cheques, transactions])

  const paymentDates = useMemo(() => payments.filter((p) => p.date).map((p) => p.date), [payments])

  const isPastSelected = useMemo(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    return selectedDay && selectedDay < today
  }, [selectedDay])

  const displayedPayments = useMemo(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    // Eğer seçilen tarih geçmişteyse (bugünden önceyse)
    if (selectedDay && selectedDay < today) {
      // Sadece o geçmiş güne ait ödemeleri filtrele
      return payments.filter((p) => p.date && isSameDay(p.date, selectedDay))
    }

    // Seçilen tarih bugün veya gelecekteyse
    // Tıklanan özel gün için ödeme(ler) varsa onu göster
    if (selectedDay) {
      const forDay = payments.filter((p) => p.date && isSameDay(p.date, selectedDay))
      if (forDay.length > 0) return forDay
    }

    // Varsayılan / Genel durum: Sadece bugünün ve geleceğin ödemelerini göster
    return payments.filter((p) => p.date && p.date >= today)
  }, [payments, selectedDay])

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

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', marginTop: '1.75rem', alignItems: 'start' }}>
        {/* SOL SÜTUN: Borç Grupları */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <DebtSection title="BANKA BORÇLARI" items={bankaBorclari} icon={Wallet} onNew={() => setModalOpen(true)} />
          <DebtSection title="TİCARİ BORÇLAR" items={ticariBorclar} icon={HardHat} onNew={() => setModalOpen(true)} />
          <DebtSection title="ÇEKLER" items={cekler} icon={Receipt} onNew={() => setModalOpen(true)} />
        </div>

        {/* SAĞ SÜTUN: Takvim & Yaklaşan Ödemeler */}
        <div>
          <div className="section-header" style={{ justifyContent: 'center', textAlign: 'center' }}>
            <span className="section-title">VADESİ DOLAN VE YAKLAŞAN ÖDEMELER</span>
          </div>
          <div className="calendar-card">
            <MiniCalendar selectedDay={selectedDay} onSelectDay={setSelectedDay} paymentDates={paymentDates} />
            <div className="calendar-divider" />
            <div className="payment-list">
              {displayedPayments.length === 0 ? (
                <div className="debt-empty">
                  {isPastSelected 
                    ? "Bu tarihte geçmiş bir ödeme kaydı bulunmuyor." 
                    : "Yaklaşan ödeme bulunmuyor."}
                </div>
              ) : (
                displayedPayments.map((p, i) => (
                  <div className="payment-row" key={i}>
                    <span className="payment-date">{fmtDate(p.date, p.rawDate)}</span>
                    <span className="payment-title">{p.title}</span>
                    <span className="payment-amount">{formatCurrency(p.amount)}</span>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>

      {modalOpen && (
        <NewDebtModal
          projects={projects}
          onClose={() => setModalOpen(false)}
          onSave={addDebt}
        />
      )}
    </div>
  )
}
