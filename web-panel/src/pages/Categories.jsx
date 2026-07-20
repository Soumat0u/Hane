import { useState, useMemo } from 'react'
import { createPortal } from 'react-dom'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Plus, X, Pencil, Trash2, Folder, FolderTree, Search, CornerDownRight } from 'lucide-react'
import { useData } from '../context/DataContext'

export default function Categories() {
  const navigate = useNavigate()
  const { categories, addCategory, updateCategory, deleteCategory } = useData()

  const [filterType, setFilterType] = useState('all') // 'all' | 'cost' | 'income'
  const [searchTerm, setSearchTerm] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [err, setErr] = useState('')

  const [form, setForm] = useState({ id: null, name: '', type: 'cost', group: '', parent: '' })

  const handleOpen = (cat = null, defaultParentId = null) => {
    setErr('')
    if (cat) {
      setForm({
        id: cat.id,
        name: cat.name || '',
        type: cat.type || 'cost',
        group: cat.group || '',
        parent: cat.parent ? String(cat.parent) : '',
      })
    } else if (defaultParentId) {
      const parentCat = categories.find((c) => Number(c.id) === Number(defaultParentId))
      setForm({
        id: null,
        name: '',
        type: parentCat?.type || 'cost',
        group: parentCat?.group || '',
        parent: String(defaultParentId),
      })
    } else {
      setForm({
        id: null,
        name: '',
        type: filterType === 'income' ? 'income' : 'cost',
        group: '',
        parent: '',
      })
    }
    setIsModalOpen(true)
  }

  const handleSave = async (e) => {
    if (e) e.preventDefault()
    if (!form.name.trim()) {
      setErr('Kategori adı zorunludur.')
      return
    }
    try {
      setIsSaving(true)
      setErr('')
      const payload = {
        name: form.name.trim(),
        type: form.type,
        group: form.group.trim() || 'Diğer',
        parent: form.parent ? parseInt(form.parent, 10) : null,
      }
      if (form.id) {
        await updateCategory(form.id, payload)
      } else {
        await addCategory(payload)
      }
      setIsModalOpen(false)
    } catch {
      setErr('Kategori kaydedilemedi. Lütfen tekrar deneyin.')
    } finally {
      setIsSaving(false)
    }
  }

  const handleDelete = async (cat) => {
    const subcats = categories.filter((c) => c.parent && Number(c.parent) === Number(cat.id))
    let message = `"${cat.name}" kategorisini silmek istediğinize emin misiniz?`
    if (subcats.length > 0) {
      message += `\n\nUyarı: Bu kategorinin ${subcats.length} adet alt kategorisi bulunmaktadır.`
    }
    if (!window.confirm(message)) return
    try {
      await deleteCategory(cat.id)
    } catch {
      alert('Kategori silinemedi. Lütfen tekrar deneyin.')
    }
  }

  // Potential root categories available to be selected as parent
  const availableParents = useMemo(() => {
    return categories.filter(
      (c) =>
        !c.parent &&
        c.type === form.type &&
        (form.id ? Number(c.id) !== Number(form.id) : true),
    )
  }, [categories, form.type, form.id])

  // Filter root categories for view
  const filteredRootCategories = useMemo(() => {
    const query = searchTerm.trim().toLowerCase()
    return categories.filter((c) => {
      if (c.parent) return false // Only root categories
      if (filterType !== 'all' && c.type !== filterType) return false

      if (!query) return true

      const subcats = categories.filter((sc) => sc.parent && Number(sc.parent) === Number(c.id))
      const matchesName = (c.name || '').toLowerCase().includes(query)
      const matchesGroup = (c.group || '').toLowerCase().includes(query)
      const matchesSub = subcats.some((sc) => (sc.name || '').toLowerCase().includes(query))

      return matchesName || matchesGroup || matchesSub
    })
  }, [categories, filterType, searchTerm])

  return (
    <div>
      <div className="page-header-banner" style={{ background: 'var(--color-primary)' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
            <button className="icon-btn" style={{ color: 'white', padding: 0 }} onClick={() => navigate(-1)}>
              <ArrowLeft size={20} />
            </button>
            <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)', margin: 0 }}>AYARLAR</div>
          </div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: 'white' }}>Kategori Yönetimi</div>
        </div>
        <div className="total-card-icon">
          <FolderTree size={36} color="#ffffff" />
        </div>
      </div>

      <div style={{ marginTop: '1.5rem' }}>
        {/* Controls: Search, Tabs, Add Button */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
            {/* Filter Tabs */}
            <div className="tab-group" style={{ display: 'inline-flex', background: 'var(--color-surface)', padding: '3px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)' }}>
              <button
                type="button"
                className={`tab-item ${filterType === 'all' ? 'active' : ''}`}
                onClick={() => setFilterType('all')}
                style={{ padding: '0.4rem 0.9rem', fontSize: '0.85rem', fontWeight: 600, border: 'none', borderRadius: 'var(--radius-sm)', cursor: 'pointer', background: filterType === 'all' ? 'var(--color-primary)' : 'transparent', color: filterType === 'all' ? '#fff' : 'var(--color-text-muted)' }}
              >
                Tümü ({categories.length})
              </button>
              <button
                type="button"
                className={`tab-item ${filterType === 'cost' ? 'active' : ''}`}
                onClick={() => setFilterType('cost')}
                style={{ padding: '0.4rem 0.9rem', fontSize: '0.85rem', fontWeight: 600, border: 'none', borderRadius: 'var(--radius-sm)', cursor: 'pointer', background: filterType === 'cost' ? 'var(--color-primary)' : 'transparent', color: filterType === 'cost' ? '#fff' : 'var(--color-text-muted)' }}
              >
                Gider ({categories.filter((c) => c.type === 'cost').length})
              </button>
              <button
                type="button"
                className={`tab-item ${filterType === 'income' ? 'active' : ''}`}
                onClick={() => setFilterType('income')}
                style={{ padding: '0.4rem 0.9rem', fontSize: '0.85rem', fontWeight: 600, border: 'none', borderRadius: 'var(--radius-sm)', cursor: 'pointer', background: filterType === 'income' ? 'var(--color-primary)' : 'transparent', color: filterType === 'income' ? '#fff' : 'var(--color-text-muted)' }}
              >
                Gelir ({categories.filter((c) => c.type === 'income').length})
              </button>
            </div>

            {/* Search Box */}
            <div style={{ position: 'relative', width: 220 }}>
              <Search size={16} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
              <input
                type="text"
                className="form-input"
                style={{ paddingLeft: '2.1rem', height: 36, fontSize: '0.85rem' }}
                placeholder="Kategori veya grup ara..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <button className="btn-primary" onClick={() => handleOpen()} style={{ width: 'auto', marginTop: 0 }}>
            <Plus size={18} /> Yeni Kategori Ekle
          </button>
        </div>

        {/* Category Tree List */}
        <div className="list-group">
          {filteredRootCategories.length === 0 ? (
            <div style={{ padding: '3rem 1.5rem', textAlign: 'center', color: 'var(--color-text-muted)', background: 'var(--color-surface)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)' }}>
              Kategori bulunamadı.
            </div>
          ) : (
            filteredRootCategories.map((root) => {
              const subcats = categories.filter((c) => c.parent && Number(c.parent) === Number(root.id))
              const isIncome = root.type === 'income'

              return (
                <div
                  key={root.id}
                  style={{
                    background: 'var(--color-surface)',
                    borderRadius: 'var(--radius-lg)',
                    border: '1px solid var(--color-border)',
                    overflow: 'hidden',
                    marginBottom: '1rem',
                  }}
                >
                  {/* Root Category Row */}
                  <div
                    style={{
                      padding: '1rem 1.25rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      borderBottom: subcats.length > 0 ? '1px solid var(--color-border)' : 'none',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
                      <div
                        style={{
                          width: 36,
                          height: 36,
                          borderRadius: '10px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          backgroundColor: isIncome ? 'rgba(16, 185, 129, 0.12)' : 'rgba(239, 68, 68, 0.12)',
                          color: isIncome ? 'var(--color-success)' : 'var(--color-danger)',
                        }}
                      >
                        <Folder size={18} />
                      </div>
                      <div>
                        <div style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--color-text-main)' }}>
                          {root.name}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.2rem', fontSize: '0.78rem', color: 'var(--color-text-muted)' }}>
                          <span
                            style={{
                              padding: '0.1rem 0.5rem',
                              borderRadius: '4px',
                              fontWeight: 600,
                              fontSize: '0.72rem',
                              backgroundColor: isIncome ? 'rgba(16, 185, 129, 0.12)' : 'rgba(239, 68, 68, 0.12)',
                              color: isIncome ? 'var(--color-success)' : 'var(--color-danger)',
                            }}
                          >
                            {isIncome ? 'Gelir' : 'Gider'}
                          </span>
                          {root.group && <span>• {root.group}</span>}
                          <span>• {subcats.length} Alt Kategori</span>
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                      <button
                        type="button"
                        className="btn-inline-text"
                        style={{ fontSize: '0.8rem', marginRight: '0.5rem' }}
                        onClick={() => handleOpen(null, root.id)}
                        title="Alt kategori ekle"
                      >
                        <Plus size={14} /> Alt Kategori
                      </button>
                      <button
                        type="button"
                        className="icon-btn"
                        onClick={() => handleOpen(root)}
                        title="Düzenle"
                      >
                        <Pencil size={16} />
                      </button>
                      <button
                        type="button"
                        className="icon-btn"
                        onClick={() => handleDelete(root)}
                        style={{ color: 'var(--color-danger)' }}
                        title="Sil"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>

                  {/* Subcategories List */}
                  {subcats.length > 0 && (
                    <div
                      style={{
                        padding: '0.75rem 1.25rem 0.85rem 3rem',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '0.5rem',
                        background: 'var(--color-surface-variant)',
                      }}
                    >
                      {subcats.map((sub) => (
                        <div
                          key={sub.id}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            padding: '0.55rem 0.85rem',
                            background: 'var(--color-surface)',
                            borderRadius: 'var(--radius-md)',
                            border: '1px solid var(--color-border)',
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.88rem', fontWeight: 600 }}>
                            <CornerDownRight size={14} className="text-muted" />
                            <span>{sub.name}</span>
                          </div>
                          <div style={{ display: 'flex', gap: '0.35rem' }}>
                            <button
                              type="button"
                              className="icon-btn"
                              onClick={() => handleOpen(sub)}
                              title="Düzenle"
                            >
                              <Pencil size={14} />
                            </button>
                            <button
                              type="button"
                              className="icon-btn"
                              onClick={() => handleDelete(sub)}
                              style={{ color: 'var(--color-danger)' }}
                              title="Sil"
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )
            })
          )}
        </div>
      </div>

      {/* Edit / Add Modal */}
      {isModalOpen && createPortal(
        <div className="modal-overlay" onClick={() => !isSaving && setIsModalOpen(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <span className="modal-title">{form.id ? 'Kategoriyi Düzenle' : 'Yeni Kategori'}</span>
              <button
                type="button"
                className="modal-close"
                onClick={() => setIsModalOpen(false)}
                disabled={isSaving}
                title="Kapat"
              >
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSave}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {err && <div className="error-message">{err}</div>}

                <div className="form-group">
                  <label className="form-label">Kategori Adı</label>
                  <input
                    type="text"
                    className="form-input"
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    placeholder="Örn. İnşaat Malzemeleri"
                    autoFocus
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Türü</label>
                  <select
                    className="form-input"
                    value={form.type}
                    onChange={(e) => {
                      const newType = e.target.value
                      setForm({ ...form, type: newType, parent: '' })
                    }}
                  >
                    <option value="cost">Maliyet / Gider</option>
                    <option value="income">Gelir</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Grup</label>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="Örn. Malzeme, İşçilik, Genel"
                    value={form.group}
                    onChange={(e) => setForm({ ...form, group: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Üst Kategori (Alt Kategori İse Seçin)</label>
                  <select
                    className="form-input"
                    value={form.parent || ''}
                    onChange={(e) => setForm({ ...form, parent: e.target.value })}
                  >
                    <option value="">- Ana Kategori (Üst Kategori Yok) -</option>
                    {availableParents.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => setIsModalOpen(false)}
                  disabled={isSaving}
                >
                  İptal
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  style={{ width: 'auto', marginTop: 0 }}
                  disabled={isSaving}
                >
                  {isSaving ? <><span className="loader" /> Kaydediliyor...</> : 'Kaydet'}
                </button>
              </div>
            </form>
          </div>
        </div>,
        document.body,
      )}
    </div>
  )
}
