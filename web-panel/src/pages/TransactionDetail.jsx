import { useMemo, useState } from 'react'
import { createPortal } from 'react-dom'
import { useParams, useNavigate } from 'react-router-dom'
import {
  ChevronLeft, MoreHorizontal, Pencil, Trash2, X,
  Tag, User, Building2, Wallet, Banknote, CalendarClock, Calendar, FileText,
} from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'
import { txVisuals, INCOME_TYPES } from '../txVisuals'
import NewTransactionFormModal from '../components/NewTransactionFormModal'

const isImageFile = (url) => /\.(png|jpe?g|gif|webp|bmp|svg)$/i.test(url || '')

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
  return createPortal(
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
    </div>,
    document.body
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



  const handleDelete = async () => {
    await deleteTransaction(t.id)
    if (window.history.length > 2) {
      navigate(-1)
    } else {
      navigate('/dashboard/transactions')
    }
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
            {isPastMonth ? (
              <span 
                className="status-badge-inline" 
                style={{ background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: '0.8rem', padding: '0.4rem 0.8rem', borderRadius: '6px' }}
                title="Geçmiş aylara ait hareketler kilitlidir."
              >
                Kilitli
              </span>
            ) : (
              <button 
                className="icon-btn" 
                onClick={() => setMenuOpen((o) => !o)} 
                style={{ background: 'rgba(255,255,255,0.2)', color: '#fff', border: 'none' }}
              >
                <MoreHorizontal size={20} />
              </button>
            )}
            {!isPastMonth && menuOpen && (
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
            {t.document_no && <DetailRow icon={FileText} label="Fatura No" value={t.document_no} />}
          </div>
        </div>

        {/* SAĞ SÜTUN: Fiş/Fatura Görseli */}
        {t.attachment && (
          <div>
            <div className="section-header">
              <span className="section-title">FİŞ / FATURA</span>
            </div>
            <a
              href={t.attachment}
              target="_blank"
              rel="noreferrer"
              className="document-card"
              style={{ width: '100%', maxWidth: 280 }}
            >
              <div className="document-card-preview" style={{ aspectRatio: '3 / 4' }}>
                {isImageFile(t.attachment) ? (
                  <img src={t.attachment} alt="Fiş/Fatura" />
                ) : (
                  <FileText size={40} className="text-primary" />
                )}
              </div>
            </a>
          </div>
        )}
      </div>
      {/* Grid Layout End */}

      {editOpen && <NewTransactionFormModal type={t.type} initialTransaction={t} onClose={() => setEditOpen(false)} />}
      {deleteOpen && <DeleteModal onClose={() => setDeleteOpen(false)} onConfirm={handleDelete} />}
    </div>
  )
}
