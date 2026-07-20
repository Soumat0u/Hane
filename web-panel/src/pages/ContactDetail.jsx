import { useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, ArrowUpRight, ArrowDownLeft, History, Pencil, Trash2 } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'
import { CONTACT_KIND_LABELS, ContactFormModal } from './Contacts'

const fmtDate = (raw) => {
  if (!raw) return '-'
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

export default function ContactDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { contacts, transactions, updateContact, deleteContact, loading, loaded } = useData()
  const [editOpen, setEditOpen] = useState(false)
  const [deleting, setDeleting] = useState(false)

  const contact = useMemo(
    () => contacts.find((c) => String(c.id) === String(id)) || null,
    [contacts, id],
  )

  const relatedTx = useMemo(() => {
    if (!contact) return []
    const list = transactions.filter((t) => t.contact === contact.id || t.contact_name === contact.name)
    return [...list].sort((a, b) => new Date(b.date) - new Date(a.date))
  }, [transactions, contact])

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  if (!contact) {
    return (
      <div>
        <button className="btn-inline-text" onClick={() => navigate(-1)} style={{ marginBottom: '1rem' }}>
          <ArrowLeft size={16} /> Geri
        </button>
        <div className="summary-box">
          <div className="empty-state">
            <span className="text-danger" style={{ fontWeight: 700 }}>Cari bulunamadı.</span>
          </div>
        </div>
      </div>
    )
  }

  const balance = num(contact.balance)
  const isDebt = balance > 0
  const isCredit = balance < 0
  const color = isDebt ? 'var(--color-danger)' : (isCredit ? 'var(--color-success)' : 'var(--color-text-muted)')

  const handleDelete = async () => {
    if (!window.confirm('Bu cariyi silmek istediğinize emin misiniz?')) return
    setDeleting(true)
    try {
      await deleteContact(contact.id)
      navigate('/dashboard/contacts')
    } catch {
      alert('Cari silinemedi.')
      setDeleting(false)
    }
  }

  return (
    <div>
      <div className="detail-topbar">
        <button className="icon-btn" onClick={() => navigate(-1)} title="Geri">
          <ArrowLeft size={20} />
        </button>
        <h1 className="detail-title">{contact.name}</h1>
        <div style={{ display: 'flex', gap: '0.5rem', marginLeft: 'auto' }}>
          <button className="icon-btn" onClick={() => setEditOpen(true)} title="Düzenle"><Pencil size={18} /></button>
          <button className="icon-btn" onClick={handleDelete} disabled={deleting} style={{ color: 'var(--color-danger)' }} title="Sil"><Trash2 size={18} /></button>
        </div>
      </div>

      <div className="summary-box" style={{ padding: '1.5rem', marginBottom: '1.5rem' }}>
        <div style={{ textAlign: 'center' }}>
          <div className="summary-label" style={{ marginBottom: '0.5rem' }}>{isDebt ? 'BORCUMUZ' : (isCredit ? 'ALACAĞIMIZ' : 'BAKİYE')}</div>
          <div style={{ fontSize: '2rem', fontWeight: 700, color }}>{formatCurrency(Math.abs(balance))}</div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem', marginTop: '1rem', flexWrap: 'wrap' }}>
          <span className="status-badge-inline" style={{ color: 'var(--color-accent)', backgroundColor: 'var(--color-accentBg)' }}>
            {CONTACT_KIND_LABELS[contact.kind] || contact.kind}
          </span>
          {contact.phone && <span className="status-badge-inline">{contact.phone}</span>}
          {contact.email && <span className="status-badge-inline">{contact.email}</span>}
        </div>
        {contact.note && (
          <div style={{ marginTop: '1rem', textAlign: 'center', color: 'var(--color-text-muted)', fontSize: '0.85rem' }}>{contact.note}</div>
        )}
      </div>

      <div className="section-header" style={{ marginTop: 0 }}>
        <span className="section-title">İLİŞKİLİ İŞLEMLER</span>
        <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--color-text-muted)' }}>{relatedTx.length} İşlem</span>
      </div>

      {relatedTx.length === 0 ? (
        <div className="empty-state" style={{ padding: '4rem 0' }}>
          <History size={44} />
          <span style={{ fontWeight: 600 }}>Bu cariye ait işlem bulunmuyor.</span>
        </div>
      ) : (
        <div className="list-group">
          {relatedTx.map((t) => {
            const isIncome = t.type === 'Gelir' || t.type === 'Tahsilat' || t.type === 'Satış'
            const Icon = isIncome ? ArrowDownLeft : ArrowUpRight
            const color2 = isIncome ? 'var(--color-success)' : 'var(--color-danger)'
            return (
              <div
                className="list-item"
                key={t.id}
                onClick={() => navigate(`/dashboard/transactions/${t.id}`)}
                style={{ cursor: 'pointer' }}
              >
                <div className="list-icon-box" style={{ background: `color-mix(in srgb, ${color2} 15%, transparent)`, color: color2 }}>
                  <Icon size={20} />
                </div>
                <div className="list-item-content">
                  <div className="list-item-title">{t.description || t.category || t.type}</div>
                  <div className="list-item-subtitle">
                    {fmtDate(t.date)}{t.document_no ? ` · Fatura No: ${t.document_no}` : ''}
                  </div>
                </div>
                <div className="list-item-value" style={{ color: color2 }}>
                  {isIncome ? '+' : '-'}{formatCurrency(t.amount)}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {editOpen && (
        <ContactFormModal
          contact={contact}
          onClose={() => setEditOpen(false)}
          onSave={(body) => updateContact(contact.id, body)}
        />
      )}
    </div>
  )
}
