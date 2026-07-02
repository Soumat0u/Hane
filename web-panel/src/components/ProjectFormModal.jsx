import { useState } from 'react'
import { createPortal } from 'react-dom'
import { X, Home, Store, Landmark, MoreHorizontal } from 'lucide-react'

export const PROJECT_TYPES = [
  { value: 'Konut', icon: Home },
  { value: 'İşyeri', icon: Store },
  { value: 'Ofis', icon: Landmark },
  { value: 'Diğer', icon: MoreHorizontal },
]

export const STATUS_OPTIONS = [
  { status: 'Planlama Aşaması', color: 'F59E0B', bg: 'FFF7ED' },
  { status: 'İhale Aşaması', color: '3B82F6', bg: 'EFF6FF' },
  { status: 'Devam Ediyor', color: '10B981', bg: 'ECFDF5' },
  { status: 'Tamamlandı', color: '64748B', bg: 'F8FAFC' },
]

const EMPTY_FORM = {
  name: '',
  project_code: '',
  project_type: 'Konut',
  location: '',
  pafta: '',
  parsel: '',
  area_sq_meters: '',
  total_independent_sections: '',
  unit_count: '',
  shop_count: '',
  start_date: '',
  end_date: '',
  estimated_total_cost: '',
  estimated_total_revenue: '',
  status: STATUS_OPTIONS[0].status,
  description: '',
}

/** Proje oluşturma/düzenleme modalı. `project` verilirse düzenleme, verilmezse yeni proje oluşturma modu. */
export default function ProjectFormModal({ project, onClose, onSave, onDelete }) {
  const [form, setForm] = useState(project ? { ...project } : EMPTY_FORM)
  const [isSaving, setIsSaving] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)

  const handleSave = async () => {
    if (!form.name || !form.name.trim()) {
      alert('Proje adı zorunludur.')
      return
    }
    try {
      setIsSaving(true)
      const selectedStatus = STATUS_OPTIONS.find((s) => s.status === form.status)
      await onSave({
        ...form,
        status_color_hex: selectedStatus?.color ?? form.status_color_hex,
        status_bg_color_hex: selectedStatus?.bg ?? form.status_bg_color_hex,
      })
      onClose()
    } catch {
      alert(project ? 'Proje güncellenemedi.' : 'Proje oluşturulamadı.')
    } finally {
      setIsSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!onDelete) return
    if (!window.confirm('Bu projeyi silmek istediğinize emin misiniz? Tüm proje verileri silinecektir.')) return
    try {
      setIsDeleting(true)
      await onDelete()
      onClose()
    } catch {
      alert('Proje silinemedi.')
      setIsDeleting(false)
    }
  }

  return createPortal(
    <div className="modal-overlay" onClick={() => !isSaving && onClose()}>
      <div className="modal" style={{ maxWidth: 760 }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">{project ? 'Projeyi Düzenle' : 'Yeni Proje'}</h2>
          <button className="modal-close" onClick={onClose} disabled={isSaving}>
            <X size={20} />
          </button>
        </div>
        <div className="modal-body" style={{ display: 'grid', gap: '0.25rem' }}>
          <div className="form-group">
            <label className="form-label">Proje Adı</label>
            <input
              type="text"
              className="form-input"
              value={form.name || ''}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              autoFocus
            />
          </div>

          <div className="form-group">
            <label className="form-label">Proje Kodu</label>
            <input
              type="text"
              className="form-input"
              placeholder="örn. AKP-001"
              value={form.project_code || ''}
              onChange={(e) => setForm({ ...form, project_code: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Proje Tipi</label>
            <div className="type-chip-grid">
              {PROJECT_TYPES.map(({ value, icon: Icon }) => (
                <button
                  type="button"
                  key={value}
                  className={`type-chip ${form.project_type === value ? 'active' : ''}`}
                  onClick={() => setForm({ ...form, project_type: value })}
                >
                  <Icon size={20} />
                  {value}
                </button>
              ))}
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Lokasyon</label>
            <input
              type="text"
              className="form-input"
              value={form.location || ''}
              onChange={(e) => setForm({ ...form, location: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Pafta</label>
              <input
                type="text"
                className="form-input"
                value={form.pafta || ''}
                onChange={(e) => setForm({ ...form, pafta: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Parsel</label>
              <input
                type="text"
                className="form-input"
                value={form.parsel || ''}
                onChange={(e) => setForm({ ...form, parsel: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Alan (m²)</label>
              <input
                type="number"
                className="form-input"
                value={form.area_sq_meters || ''}
                onChange={(e) => setForm({ ...form, area_sq_meters: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Toplam Bağımsız Bölüm</label>
              <input
                type="number"
                className="form-input"
                placeholder="örn. 48"
                value={form.total_independent_sections || ''}
                onChange={(e) => setForm({ ...form, total_independent_sections: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Konut Sayısı</label>
              <input
                type="number"
                className="form-input"
                placeholder="örn. 40"
                value={form.unit_count || ''}
                onChange={(e) => setForm({ ...form, unit_count: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">İşyeri Sayısı</label>
              <input
                type="number"
                className="form-input"
                placeholder="örn. 8"
                value={form.shop_count || ''}
                onChange={(e) => setForm({ ...form, shop_count: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Başlangıç Tarihi</label>
              <input
                type="date"
                className="form-input"
                value={form.start_date || ''}
                onChange={(e) => setForm({ ...form, start_date: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Tahmini Bitiş Tarihi</label>
              <input
                type="date"
                className="form-input"
                value={form.end_date || ''}
                onChange={(e) => setForm({ ...form, end_date: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div className="form-group">
              <label className="form-label">Öngörülen Toplam Maliyet (₺)</label>
              <input
                type="number"
                className="form-input"
                value={form.estimated_total_cost || ''}
                onChange={(e) => setForm({ ...form, estimated_total_cost: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Öngörülen Toplam Gelir (₺)</label>
              <input
                type="number"
                className="form-input"
                value={form.estimated_total_revenue || ''}
                onChange={(e) => setForm({ ...form, estimated_total_revenue: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Durum</label>
            <select
              className="form-input"
              value={form.status || ''}
              onChange={(e) => setForm({ ...form, status: e.target.value })}
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s.status} value={s.status}>{s.status}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Açıklama (Opsiyonel)</label>
            <textarea
              className="form-input textarea-field"
              rows={3}
              maxLength={500}
              placeholder="Proje hakkında not ekleyebilirsiniz..."
              value={form.description || ''}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
          </div>
        </div>
        <div className="modal-footer">
          {onDelete && (
            <button className="btn-danger-outline" onClick={handleDelete} disabled={isSaving || isDeleting}>
              {isDeleting ? <span className="loader"></span> : 'Projeyi Sil'}
            </button>
          )}
          <button className="btn-secondary" onClick={onClose} disabled={isSaving}>
            İptal
          </button>
          <button className="btn-primary" style={{ width: 'auto', marginTop: 0 }} onClick={handleSave} disabled={isSaving}>
            {isSaving ? <span className="loader"></span> : 'Kaydet'}
          </button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
