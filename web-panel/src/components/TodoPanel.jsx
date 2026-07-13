import { useState } from 'react'
import { Plus, Trash2, User, FolderKanban } from 'lucide-react'
import { useData } from '../context/DataContext'

/**
 * Basit yapılacaklar listesi: üstteki Kişisel/Projeler sekmesinden geçiş yapılır.
 * Kişisel listede proje seçimi yok; Projeler listesinde her yeni madde bir
 * projeye bağlanır ve satırda o projenin adı küçük bir etiket olarak görünür.
 */
export default function TodoPanel() {
  const { todos, projects, addTodo, updateTodo, deleteTodo } = useData()
  const [tab, setTab] = useState('personal') // 'personal' | 'project'
  const [title, setTitle] = useState('')
  const [projectId, setProjectId] = useState('')
  const [saving, setSaving] = useState(false)

  const list = todos.filter((t) => {
    if (t.scope !== tab) return false
    if (tab === 'project') return projectId && String(t.project) === String(projectId)
    return true
  })

  const handleAdd = async (e) => {
    e.preventDefault()
    const trimmed = title.trim()
    if (!trimmed) return
    if (tab === 'project' && !projectId) return
    setSaving(true)
    try {
      await addTodo({
        title: trimmed,
        scope: tab,
        project: tab === 'project' ? Number(projectId) : null,
      })
      setTitle('')
    } catch (err) {
      console.error('Yapılacak eklenemedi:', err)
      alert('Yapılacak eklenemedi.')
    } finally {
      setSaving(false)
    }
  }

  const handleToggle = async (t) => {
    try {
      await updateTodo(t.id, { ...t, is_done: !t.is_done })
    } catch {
      alert('Güncellenemedi.')
    }
  }

  const handleDelete = async (id) => {
    try {
      await deleteTodo(id)
    } catch {
      alert('Silinemedi.')
    }
  }

  return (
    <div className="spending-card" style={{ marginBottom: 0 }}>
      <div className="section-header">
        <span className="section-title">YAPILACAKLAR</span>
      </div>

      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
        <button
          type="button"
          className={`type-chip ${tab === 'personal' ? 'active' : ''}`}
          style={{ flexDirection: 'row', gap: '0.4rem' }}
          onClick={() => setTab('personal')}
        >
          <User size={14} /> Kişisel
        </button>
        <button
          type="button"
          className={`type-chip ${tab === 'project' ? 'active' : ''}`}
          style={{ flexDirection: 'row', gap: '0.4rem' }}
          onClick={() => setTab('project')}
        >
          <FolderKanban size={14} /> Projeler
        </button>
      </div>

      {tab === 'project' && (
        <div className="form-group" style={{ marginBottom: '1rem' }}>
          <select className="form-input" value={projectId} onChange={(e) => setProjectId(e.target.value)}>
            <option value="">Proje seçin...</option>
            {projects.map((p) => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
        </div>
      )}

      {(tab === 'personal' || projectId) && (
        <form onSubmit={handleAdd} style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
          <input
            type="text"
            className="form-input"
            placeholder="Yeni madde ekle..."
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
          <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0, padding: '0 1rem' }} disabled={saving || !title.trim()}>
            <Plus size={16} />
          </button>
        </form>
      )}

      {tab === 'project' && !projectId ? (
        <div className="summary-box">
          <div className="empty-state" style={{ padding: '1.25rem 0' }}>
            <span>Maddeleri görmek için bir proje seçin.</span>
          </div>
        </div>
      ) : list.length === 0 ? (
        <div className="summary-box">
          <div className="empty-state" style={{ padding: '1.25rem 0' }}>
            <span>{tab === 'personal' ? 'Henüz kişisel madde yok.' : 'Bu projede henüz madde yok.'}</span>
          </div>
        </div>
      ) : (
        <div className="list-group">
          {list.map((t) => (
            <div className="list-item" key={t.id}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flex: 1, cursor: 'pointer' }}>
                <input type="checkbox" checked={!!t.is_done} onChange={() => handleToggle(t)} />
                <div className="list-item-content">
                  <div
                    className="list-item-title"
                    style={{ textDecoration: t.is_done ? 'line-through' : 'none', color: t.is_done ? 'var(--color-text-muted)' : undefined }}
                  >
                    {t.title}
                  </div>
                </div>
              </label>
              <button className="icon-btn" onClick={() => handleDelete(t.id)} title="Sil">
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
