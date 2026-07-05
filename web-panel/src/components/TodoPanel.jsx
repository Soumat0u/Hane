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

  const list = todos.filter((t) => t.scope === tab)

  const projectName = (id) => projects.find((p) => String(p.id) === String(id))?.name || ''

  const handleAdd = async (e) => {
    e.preventDefault()
    const trimmed = title.trim()
    if (!trimmed) return
    setSaving(true)
    try {
      await addTodo({
        title: trimmed,
        scope: tab,
        project: tab === 'project' && projectId ? Number(projectId) : null,
      })
      setTitle('')
    } catch {
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
    <div>
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

      <form onSubmit={handleAdd} style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
        <input
          type="text"
          className="form-input"
          placeholder="Yeni madde ekle..."
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        {tab === 'project' && (
          <select className="form-input" style={{ maxWidth: 180 }} value={projectId} onChange={(e) => setProjectId(e.target.value)}>
            <option value="">Proje seç</option>
            {projects.map((p) => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
        )}
        <button type="submit" className="btn-primary" style={{ width: 'auto', marginTop: 0, padding: '0 1rem' }} disabled={saving || !title.trim()}>
          <Plus size={16} />
        </button>
      </form>

      {list.length === 0 ? (
        <div className="summary-box">
          <div className="empty-state" style={{ padding: '1.25rem 0' }}>
            <span>{tab === 'personal' ? 'Henüz kişisel madde yok.' : 'Henüz proje maddesi yok.'}</span>
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
                  {tab === 'project' && t.project && (
                    <div className="list-item-subtitle">{projectName(t.project)}</div>
                  )}
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
