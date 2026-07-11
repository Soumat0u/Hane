import { useMemo, useState } from 'react'
import { ChevronLeft, ChevronRight, Repeat } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'
import RecurringFormModal, { DeleteRecurringModal } from './RecurringFormModal'

// Vadesi henüz gelmemiş ama bu kadar gün içinde olan tekrarlayan işlem şablonları
// takvimde/bildirimlerde "yaklaşan" olarak önizlenir (vadesi gelenler sunucuda otomatik onaylanır).
const UPCOMING_RECURRING_WINDOW_DAYS = 3

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

/**
 * Yaklaşan/vadesi dolan borç ÖDEMELERİ (çekler + vadeli Gider işlemleri) ve
 * alacak/tahsilat kalemlerini (açık alacaklar) birlikte gösteren takvim paneli.
 * Eskiden Borçlar sayfasındaydı; Genel Bakış'a taşındı ve kapsamı alacakları
 * da içerecek şekilde genişletildi.
 */
export default function DueCalendarPanel() {
  const { cheques, transactions, receivables, recurringTransactions, accounts, updateRecurringTransaction, deleteRecurringTransaction } = useData()
  const [selectedDay, setSelectedDay] = useState(() => {
    const d = new Date()
    d.setHours(0, 0, 0, 0)
    return d
  })
  const [editTarget, setEditTarget] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)

  const items = useMemo(() => {
    const list = []
    cheques.forEach((c) => {
      if (c.direction === 'issued' && c.status !== 'cashed') {
        list.push({
          title: c.bank_name ? `${c.bank_name} çeki` : 'Verilen çek',
          amount: num(c.amount),
          date: parseDate(c.due_date),
          rawDate: c.due_date,
          isPayable: true,
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
          isPayable: true,
        })
      }
    })
    receivables.forEach((r) => {
      const remaining = num(r.total_amount) - num(r.collected_amount)
      if (remaining > 0) {
        list.push({
          title: r.description || 'Alacak',
          amount: remaining,
          date: parseDate(r.due_date),
          rawDate: r.due_date,
          isPayable: false,
        })
      }
    })
    const today0 = new Date()
    today0.setHours(0, 0, 0, 0)
    const limit = new Date(today0)
    limit.setDate(limit.getDate() + UPCOMING_RECURRING_WINDOW_DAYS)
    recurringTransactions.forEach((r) => {
      if (!r.is_active) return
      const d = parseDate(r.next_due_date)
      if (!d) return
      if (d > today0 && d <= limit) {
        list.push({
          title: r.description || r.category || 'Tekrarlayan işlem',
          amount: num(r.amount),
          date: d,
          rawDate: r.next_due_date,
          isPayable: r.type === 'Gider',
          recurringTemplateId: r.id,
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
  }, [cheques, transactions, receivables, recurringTransactions])

  const paymentDates = useMemo(() => items.filter((p) => p.date).map((p) => p.date), [items])

  const isPastSelected = useMemo(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    return selectedDay && selectedDay < today
  }, [selectedDay])

  const displayedItems = useMemo(() => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    if (selectedDay && selectedDay < today) {
      return items.filter((p) => p.date && isSameDay(p.date, selectedDay))
    }
    if (selectedDay) {
      const forDay = items.filter((p) => p.date && isSameDay(p.date, selectedDay))
      if (forDay.length > 0) return forDay
    }
    return items.filter((p) => p.date && p.date >= today)
  }, [items, selectedDay])

  return (
    <div>
      <div className="section-header">
        <span className="section-title">VADESİ DOLAN VE YAKLAŞAN ÖDEME/ALACAKLAR</span>
      </div>
      <div className="calendar-card">
        <MiniCalendar selectedDay={selectedDay} onSelectDay={setSelectedDay} paymentDates={paymentDates} />
        <div className="calendar-divider" />
        <div className="payment-list">
          {displayedItems.length === 0 ? (
            <div className="debt-empty">
              {isPastSelected
                ? 'Bu tarihte geçmiş bir kayıt bulunmuyor.'
                : 'Yaklaşan ödeme/alacak bulunmuyor.'}
            </div>
          ) : (
            displayedItems.map((p, i) => (
              <div
                className="payment-row"
                key={i}
                style={p.recurringTemplateId ? { cursor: 'pointer' } : undefined}
                onClick={
                  p.recurringTemplateId
                    ? () => {
                        const template = recurringTransactions.find((r) => r.id === p.recurringTemplateId)
                        if (template) setEditTarget(template)
                      }
                    : undefined
                }
              >
                <span className="payment-date">{fmtDate(p.date, p.rawDate)}</span>
                <span className="payment-title" style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                  {p.recurringTemplateId && <Repeat size={13} style={{ color: 'var(--color-accent)', flexShrink: 0 }} />}
                  {p.title}
                </span>
                <span className="payment-amount" style={{ color: p.isPayable ? 'var(--color-danger)' : 'var(--color-success)' }}>
                  {p.isPayable ? '-' : '+'}{formatCurrency(p.amount)}
                </span>
              </div>
            ))
          )}
        </div>
      </div>
      {editTarget && (
        <RecurringFormModal
          existing={editTarget}
          accounts={accounts}
          onClose={() => setEditTarget(null)}
          onSave={(body) => updateRecurringTransaction(editTarget.id, body)}
          onDelete={(r) => { setDeleteTarget({ id: r.id, description: r.description || r.category }); setEditTarget(null) }}
        />
      )}
      {deleteTarget && (
        <DeleteRecurringModal
          target={deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={async (id) => { await deleteRecurringTransaction(id); setDeleteTarget(null) }}
        />
      )}
    </div>
  )
}
