import { useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  ChevronLeft, MoreHorizontal, Pencil, Trash2, X,
  Tag, User, Building2, Wallet, Banknote, CalendarClock, Calendar,
} from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'
import { txVisuals, INCOME_TYPES } from '../txVisuals'

const fmtDate = (raw, short = false) => {
  if (!raw) return '-'
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString('tr-TR', short
    ? { day: '2-digit', month: '2-digit', year: 'numeric' }
    : { day: 'numeric', month: 'short', year: 'numeric' })
}

function DetailRow({ icon: Icon, label, value, valueColor }) {
  return (
    <div className="summary-row">
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <Icon size={18} className="text-muted" />
        <span className="summary-label">{label}</span>
      </div>
      <span className="summary-value" style={valueColor ? { color: valueColor, fontWeight: 700 } : undefined}>{value}</span>
    </div>
  )
}

function EditModal({ tx, onClose, onSave }) {
  const [description, setDescription] = useState(tx.description || '')
  const [amount, setAmount] = useState(String(num(tx.amount)))
  const [category, setCategory] = useState(tx.category || '')
  const [date, setDate] = useState((tx.date || '').slice(0, 10))
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSaving(true)
    setErr('')
    try {
      await onSave({ description, amount: num(amount), category, date })
      onClose()
    } catch {
      setErr('Güncellenemedi. Lütfen tekrar deneyin.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <span className="modal-title">İşlemi Düzenle</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={20} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {err && <div className="error-message">{err}</div>}
            <div className="input-group">
              <label className="input-label">Açıklama</label>
              <input className="input-field" value={description} onChange={(e) => setDescription(e.target.value)} autoFocus />
            </div>
            <div className="input-group">
              <label className="input-label">Tutar (₺)</label>
              <input className="input-field" type="number" min="0" step="0.01" value={amount} onChange={(e) => setAmount(e.target.value)} />
            </div>
            <div className="input-group">
              <label className="input-label">Kategori</label>
              <input className="input-field" value={category} onChange={(e) => setCategory(e.target.value)} />
            </div>
            <div className="input-group">
              <label className="input-label">Tarih</label>
              <input className="input-field" type="date" value={date} onChange={(e) => setDate(e.target.value)} />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-ghost" onClick={onClose} disabled={saving}>Vazgeç</button>
            <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0 }} disabled={saving}>
              {saving ? <><span className="loader" /> Kaydediliyor...</> : 'Kaydet'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

function DeleteModal({ onClose, onConfirm }) {
  const [deleting, setDeleting] = useState(false)
  const [err, setErr] = useState('')
  const handleDelete = async () => {
    setDeleting(true)
    setErr('')
    try {
      await onConfirm()
    } catch {
      setErr('Silinemedi. Lütfen tekrar deneyin.')
      setDeleting(false)
    }
  }
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 340 }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header" style={{ padding: '1rem 1.25rem' }}>
          <span className="modal-title">İşlemi Sil</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={18} /></button>
        </div>
        <div className="modal-body" style={{ padding: '0.25rem 1.25rem 1.1rem' }}>
          {err && <div className="error-message">{err}</div>}
          <p style={{ color: 'var(--color-text-muted)', fontSize: '0.88rem', margin: 0 }}>
            Bu işlemi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.
          </p>
        </div>
        <div className="modal-footer" style={{ padding: '0 1.25rem 1.1rem' }}>
          <button type="button" className="btn-ghost" onClick={onClose} disabled={deleting}>Vazgeç</button>
          <button type="button" className="btn-danger" onClick={handleDelete} disabled={deleting}>
            {deleting ? <><span className="loader" /> Siliniyor...</> : 'Sil'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function TransactionDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { transactions, projects, loading, loaded, updateTransaction, deleteTransaction } = useData()

  const [menuOpen, setMenuOpen] = useState(false)
  const [editOpen, setEditOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)

  const t = useMemo(
    () => transactions.find((x) => String(x.id) === String(id)) || null,
    [transactions, id],
  )

  const projectName = useMemo(() => {
    if (!t || t.project_id == null) return null
    const p = projects.find((x) => x.id === t.project_id)
    return p ? p.name : null
  }, [t, projects])

  const related = useMemo(() => {
    if (!t) return []
    const match = (x) => {
      if (x.id === t.id) return false
      if (t.category && x.category === t.category) return true
      if (t.description && x.description === t.description) return true
      if (t.contact_name && x.contact_name === t.contact_name) return true
      if (t.contact && x.contact === t.contact) return true
      return false
    }
    return transactions
      .filter(match)
      .sort((a, b) => {
        const da = a.date ? new Date(a.date) : null
        const db = b.date ? new Date(b.date) : null
        if (!da && !db) return 0
        if (!da) return 1
        if (!db) return -1
        return db - da
      })
      .slice(0, 8)
  }, [t, transactions])

  const balance = useMemo(() => {
    if (!t) return null
    const sameGroup = (x) => {
      if (t.contact != null) return x.contact === t.contact
      if (t.contact_name) return x.contact_name === t.contact_name
      if (t.project_id != null) return x.project_id === t.project_id
      return false
    }
    const group = transactions.filter(sameGroup)
    if (group.length === 0) return null
    const gelir = group.filter((x) => INCOME_TYPES.has(x.type)).reduce((s, x) => s + num(x.amount), 0)
    const gider = group.filter((x) => x.type === 'Gider').reduce((s, x) => s + num(x.amount), 0)
    const label = t.contact_name || projectName || 'Toplam'
    return { gelir, gider, net: gelir - gider, label }
  }, [t, transactions, projectName])

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  if (!t) {
    return (
      <div>
        <button className="btn-inline-text" onClick={() => navigate(-1)} style={{ marginBottom: '1rem' }}>
          <ChevronLeft size={16} /> Geri
        </button>
        <div className="summary-box">
          <div className="empty-state">
            <span className="text-danger" style={{ fontWeight: 700 }}>İşlem bulunamadı.</span>
          </div>
        </div>
      </div>
    )
  }

  const { color, Icon } = txVisuals(t.type)
  const account = t.source_name || t.dest_name
  const heading = t.description || t.category

  const handleEditSave = async ({ description, amount, category, date }) => {
    await updateTransaction(t.id, {
      project_id: t.project_id ?? null,
      type: t.type,
      amount,
      currency: t.currency || 'TRY',
      date,
      category,
      description,
      from_account: t.from_account ?? null,
      to_account: t.to_account ?? null,
      contact: t.contact ?? null,
      source_name: t.source_name || '',
      dest_name: t.dest_name || '',
      contact_name: t.contact_name || '',
      due_date: t.due_date || '',
    })
  }

  const handleDelete = async () => {
    await deleteTransaction(t.id)
    navigate('/dashboard/transactions')
  }

  return (
    <div>
      {/* Top Banner with back button and menu */}
      <div className="page-header-banner" style={{ background: color, color: '#ffffff', display: 'flex', flexDirection: 'column', alignItems: 'stretch', gap: '1.5rem', padding: '1.5rem 2rem 2rem 2rem' }}>
        
        {/* Row 1: Actions (Back button & Options button) */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
          <button 
            className="icon-btn" 
            onClick={() => navigate(-1)} 
            style={{ background: 'rgba(255,255,255,0.2)', color: '#fff', border: 'none' }}
          >
            <ChevronLeft size={20} />
          </button>
          
          <div style={{ position: 'relative' }}>
            <button 
              className="icon-btn" 
              onClick={() => setMenuOpen((o) => !o)} 
              style={{ background: 'rgba(255,255,255,0.2)', color: '#fff', border: 'none' }}
            >
              <MoreHorizontal size={20} />
            </button>
            {menuOpen && (
              <>
                <div className="menu-backdrop" onClick={() => setMenuOpen(false)} />
                <div
                  className="tx-menu"
                  style={{
                    position: 'absolute', right: 0, top: '100%', marginTop: '0.5rem',
                    background: 'var(--color-surface)', border: '1px solid var(--color-border)',
                    borderRadius: '10px', boxShadow: 'var(--shadow-lg)', padding: '0.4rem',
                    zIndex: 20, minWidth: '160px',
                  }}
                >
                  <button className="tx-menu-item" onClick={() => { setMenuOpen(false); setEditOpen(true) }}>
                    <Pencil size={16} /> Düzenle
                  </button>
                  <button className="tx-menu-item danger" onClick={() => { setMenuOpen(false); setDeleteOpen(true) }}>
                    <Trash2 size={16} /> Sil
                  </button>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Row 2: Details (Heading & Amount) */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: '1.5rem', width: '100%' }}>
          <div>
            <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.8)' }}>{(t.type || '').toUpperCase()} BİLGİSİ</div>
            <div className="total-card-value" style={{ color: '#ffffff' }}>{heading || '-'}</div>
            {t.contact_name && <div style={{ color: 'rgba(255,255,255,0.9)', marginTop: '0.5rem', fontSize: '1rem' }}>{t.contact_name}</div>}
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '0.4rem' }}>
            <div style={{ fontSize: '1.75rem', fontWeight: 800 }}>{formatCurrency(t.amount)}</div>
            <div style={{ fontSize: '0.9rem', opacity: 0.9, display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
              <Calendar size={14} /> {fmtDate(t.date)}
            </div>
          </div>
        </div>
      </div>

      {/* Grid Layout Start */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', alignItems: 'start', marginTop: '1.75rem' }}>
        
        {/* SOL SÜTUN: Detaylar */}
        <div>
          <div className="section-header">
            <span className="section-title">İŞLEM DETAYLARI</span>
          </div>
          <div className="summary-box">
            <DetailRow icon={Tag} label="Kategori" value={t.category || '-'} />
            <DetailRow icon={User} label="Alıcı / Kişi" value={t.contact_name || '-'} />
            <DetailRow icon={Building2} label="Proje" value={projectName || '-'} />
            <DetailRow icon={Wallet} label="Ödeme Kaynağı" value={account || '-'} />
            <DetailRow icon={Banknote} label="Tutar" value={formatCurrency(t.amount)} valueColor={color} />
            {t.due_date && <DetailRow icon={CalendarClock} label="Vade" value={fmtDate(t.due_date)} />}
          </div>
        </div>

        {/* SAĞ SÜTUN: Geçmiş & Bakiye */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          
          {/* İlgili işlem geçmişi */}
          {related.length > 0 && (
            <div>
              <div className="section-header">
                <span className="section-title">İLGİLİ İŞLEM GEÇMİŞİ</span>
              </div>
              <div className="list-group">
                {related.map((r) => {
                  const rv = txVisuals(r.type)
                  const rTitle = r.description || r.category || r.type
                  return (
                    <div className="list-item" key={r.id} onClick={() => navigate(`/dashboard/transactions/${r.id}`)} style={{ cursor: 'pointer' }}>
                      <div className="list-icon-box" style={{ background: `color-mix(in srgb, ${rv.color} 15%, transparent)`, color: rv.color }}>
                        <rv.Icon size={18} />
                      </div>
                      <div className="list-item-content">
                        <div className="list-item-title">{rTitle}</div>
                        <div className="list-item-subtitle">{fmtDate(r.date, true)}</div>
                      </div>
                      <div className="list-item-value-box">
                        <div className="list-item-value" style={{ color: rv.color }}>{formatCurrency(r.amount)}</div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {/* Bakiye özeti */}
          {balance && (
            <div>
              <div className="section-header">
                <span className="section-title">{balance.label.toUpperCase()} — TOPLAM BAKİYE</span>
              </div>
              <div className="summary-box">
                <div className="summary-row">
                  <span className="summary-label">Gelir / Tahsilat</span>
                  <span className="summary-value text-success">{formatCurrency(balance.gelir)}</span>
                </div>
                <div className="summary-row">
                  <span className="summary-label">Gider / Ödeme</span>
                  <span className="summary-value text-danger">{formatCurrency(balance.gider)}</span>
                </div>
                <div className="summary-total-row">
                  <span className="summary-total-label" style={{ color: balance.net >= 0 ? 'var(--color-success)' : 'var(--color-danger)' }}>NET BAKİYE</span>
                  <span className="summary-total-value" style={{ color: balance.net >= 0 ? 'var(--color-success)' : 'var(--color-danger)' }}>
                    {formatCurrency(balance.net)}
                  </span>
                </div>
              </div>
            </div>
          )}

        </div>
      </div>
      {/* Grid Layout End */}

      {editOpen && <EditModal tx={t} onClose={() => setEditOpen(false)} onSave={handleEditSave} />}
      {deleteOpen && <DeleteModal onClose={() => setDeleteOpen(false)} onConfirm={handleDelete} />}
    </div>
  )
}
