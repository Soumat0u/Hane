import { useState, useMemo } from 'react'
import { createPortal } from 'react-dom'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Plus, X, Pencil, Trash2, Folder, FolderTree } from 'lucide-react'
import { useData } from '../context/DataContext'

export default function Categories() {
  const navigate = useNavigate()
  const { categories, addCategory, updateCategory, deleteCategory } = useData()

  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  
  const [form, setForm] = useState({ id: null, name: '', type: 'cost', group: '', parent: '' })

  const handleOpen = (cat = null) => {
    if (cat) {
      setForm({
        id: cat.id,
        name: cat.name || '',
        type: cat.type || 'cost',
        group: cat.group || '',
        parent: cat.parent || ''
      })
    } else {
      setForm({ id: null, name: '', type: 'cost', group: '', parent: '' })
    }
    setIsModalOpen(true)
  }

  const handleSave = async () => {
    if (!form.name.trim()) return alert('Kategori adı zorunludur.')
    try {
      setIsSaving(true)
      const payload = {
        name: form.name,
        type: form.type,
        group: form.group,
        parent: form.parent ? parseInt(form.parent, 10) : null
      }
      if (form.id) {
        await updateCategory(form.id, payload)
      } else {
        await addCategory(payload)
      }
      setIsModalOpen(false)
    } catch (err) {
      alert('Kategori kaydedilemedi.')
    } finally {
      setIsSaving(false)
    }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Bu kategoriyi silmek istediğinize emin misiniz?')) return
    try {
      await deleteCategory(id)
    } catch (err) {
      alert('Kategori silinemedi.')
    }
  }

  const rootCategories = useMemo(() => categories.filter(c => !c.parent), [categories])
  
  return (
    <div>
      <div className="page-header-banner" style={{ background: 'var(--color-primary)' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
            <button className="icon-btn" style={{ color: 'white', padding: 0 }} onClick={() => navigate(-1)}><ArrowLeft size={20}/></button>
            <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)', margin: 0 }}>AYARLAR</div>
          </div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: 'white' }}>Kategori Yönetimi</div>
        </div>
        <div className="total-card-icon">
          <FolderTree size={36} color="#ffffff" />
        </div>
      </div>
      
      <div style={{ marginTop: '2rem' }}>
        <button className="btn-primary" onClick={() => handleOpen()} style={{ marginBottom: '1.5rem' }}>
          <Plus size={18} /> Yeni Kategori Ekle
        </button>

        <div className="list-group">
          {rootCategories.map(root => {
            const subcats = categories.filter(c => c.parent === root.id)
            return (
              <div key={root.id} style={{ background: 'var(--color-surface)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)', overflow: 'hidden', marginBottom: '1rem' }}>
                <div style={{ padding: '1rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: subcats.length > 0 ? '1px solid var(--color-border)' : 'none' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Folder size={20} className="text-primary" />
                    <div>
                      <div style={{ fontWeight: 600 }}>{root.name}</div>
                      <div style={{ fontSize: '0.8rem', color: 'var(--color-text-muted)' }}>{root.type === 'cost' ? 'Maliyet' : 'Gelir'} {root.group && `• ${root.group}`}</div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    <button className="icon-btn" onClick={() => handleOpen(root)}><Pencil size={16} /></button>
                    <button className="icon-btn" onClick={() => handleDelete(root.id)} style={{ color: 'var(--color-danger)' }}><Trash2 size={16} /></button>
                  </div>
                </div>
                {subcats.length > 0 && (
                  <div style={{ padding: '0.5rem 1rem 1rem 3rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', background: 'var(--color-surface-variant)' }}>
                    {subcats.map(sub => (
                      <div key={sub.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.5rem', background: 'var(--color-surface)', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)' }}>
                        <div style={{ fontSize: '0.9rem', fontWeight: 500 }}>{sub.name}</div>
                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                          <button className="icon-btn" onClick={() => handleOpen(sub)}><Pencil size={14} /></button>
                          <button className="icon-btn" onClick={() => handleDelete(sub.id)} style={{ color: 'var(--color-danger)' }}><Trash2 size={14} /></button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>

      {isModalOpen && createPortal(
        <div className="modal-overlay" onClick={() => !isSaving && setIsModalOpen(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2 className="modal-title">{form.id ? 'Kategoriyi Düzenle' : 'Yeni Kategori'}</h2>
              <button className="modal-close" onClick={() => setIsModalOpen(false)} disabled={isSaving}><X size={20} /></button>
            </div>
            <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div className="form-group">
                <label className="form-label">Kategori Adı</label>
                <input type="text" className="form-input" value={form.name} onChange={e => setForm({...form, name: e.target.value})} />
              </div>
              <div className="form-group">
                <label className="form-label">Tipi</label>
                <select className="form-input" value={form.type} onChange={e => setForm({...form, type: e.target.value})}>
                  <option value="cost">Maliyet/Gider</option>
                  <option value="income">Gelir</option>
                </select>
              </div>
              <div className="form-group">
                <label className="form-label">Grup</label>
                <input type="text" className="form-input" placeholder="Örn: Malzeme" value={form.group} onChange={e => setForm({...form, group: e.target.value})} />
              </div>
              <div className="form-group">
                <label className="form-label">Üst Kategori (Alt Kategori ise seçin)</label>
                <select className="form-input" value={form.parent || ''} onChange={e => setForm({...form, parent: e.target.value})}>
                  <option value="">- Ana Kategori -</option>
                  {rootCategories.filter(c => c.id !== form.id).map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setIsModalOpen(false)} disabled={isSaving}>İptal</button>
              <button className="btn-primary" onClick={handleSave} disabled={isSaving}>
                {isSaving ? <span className="loader"></span> : 'Kaydet'}
              </button>
            </div>
          </div>
        </div>,
        document.body
      )}
    </div>
  )
}
