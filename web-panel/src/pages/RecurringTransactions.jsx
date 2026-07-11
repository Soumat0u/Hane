import { useMemo, useState } from 'react'
import { Repeat, Plus, Trash2 } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency } from '../utils'
import RecurringFormModal, { DeleteRecurringModal, RECURRING_INTERVAL_LABELS } from '../components/RecurringFormModal'

export default function RecurringTransactions() {
  const { recurringTransactions, accounts, addRecurringTransaction, updateRecurringTransaction, deleteRecurringTransaction, loading, loaded } = useData()
  const [formTarget, setFormTarget] = useState(undefined) // undefined = closed, null = create, object = edit
  const [deleteTarget, setDeleteTarget] = useState(null)

  const sorted = useMemo(
    () => [...recurringTransactions].sort((a, b) => (a.next_due_date || '').localeCompare(b.next_due_date || '')),
    [recurringTransactions],
  )

  const handleDelete = (id, label) => {
    setDeleteTarget({ id, description: label })
  }

  const confirmDelete = async (id) => {
    try {
      await deleteRecurringTransaction(id)
      setDeleteTarget(null)
      setFormTarget(undefined)
    } catch {
      throw new Error('Şablon silinemedi.')
    }
  }

  const handleSave = async (body) => {
    if (formTarget && formTarget.id) {
      await updateRecurringTransaction(formTarget.id, body)
    } else {
      await addRecurringTransaction(body)
    }
  }

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  return (
    <div>
      <div className="page-header-banner" style={{ background: 'var(--color-primary)', color: '#ffffff' }}>
        <div>
          <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)' }}>TEKRARLAYAN İŞLEMLER</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: '#ffffff' }}>Vadesi gelenler otomatik oluşturulur</div>
        </div>
        <button className="btn-inline-text" style={{ color: '#ffffff' }} onClick={() => setFormTarget(null)}>
          <Plus size={18} /> Yeni Şablon
        </button>
      </div>

      {sorted.length === 0 ? (
        <div className="summary-box" style={{ marginTop: '1.75rem' }}>
          <div className="empty-state">
            <Repeat size={40} />
            <span>Henüz tekrarlayan işlem şablonu yok.</span>
          </div>
        </div>
      ) : (
        <div className="list-group" style={{ marginTop: '1.75rem' }}>
          {sorted.map((r) => (
            <div className="list-item" key={r.id} onClick={() => setFormTarget(r)} style={{ cursor: 'pointer' }}>
              <div className="list-icon-box"><Repeat size={20} className="text-primary" /></div>
              <div className="list-item-content">
                <div className="list-item-title">{r.description || r.category}</div>
                <div className="list-item-subtitle">{RECURRING_INTERVAL_LABELS[r.interval] || r.interval} • Sıradaki: {r.next_due_date}</div>
              </div>
              <div className="list-item-value">{formatCurrency(r.amount)}</div>
              <button
                className="icon-btn"
                style={{ color: 'var(--color-danger)', marginLeft: '0.5rem' }}
                onClick={(e) => { e.stopPropagation(); handleDelete(r.id, r.description || r.category) }}
                title="Sil"
              >
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      )}

      {formTarget !== undefined && (
        <RecurringFormModal
          existing={formTarget}
          accounts={accounts}
          onClose={() => setFormTarget(undefined)}
          onSave={handleSave}
          onDelete={(r) => { handleDelete(r.id, r.description || r.category); setFormTarget(undefined) }}
        />
      )}
      {deleteTarget && (
        <DeleteRecurringModal
          target={deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={confirmDelete}
        />
      )}
    </div>
  )
}
