import { useState, useRef } from 'react'
import { createPortal } from 'react-dom'
import { X, Home, Store, Landmark, MoreHorizontal, Camera, LocateFixed } from 'lucide-react'
import { projectImage, parseMoneyInput, formatAmountForDisplay } from '../utils'
import MoneyInput from './MoneyInput'
import MapLocationPicker from './MapLocationPicker'

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

export default function ProjectFormModal({ project, onClose, onSave, onDelete }) {
  const [form, setForm] = useState(project ? {
    ...project,
    estimated_total_cost: formatAmountForDisplay(project.estimated_total_cost || 0),
    estimated_total_revenue: formatAmountForDisplay(project.estimated_total_revenue || 0),
  } : EMPTY_FORM)
  const [imageFile, setImageFile] = useState(null)
  const [imagePreview, setImagePreview] = useState(project ? projectImage(project) : projectImage(null))
  const [isSaving, setIsSaving] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [mapOpen, setMapOpen] = useState(false)
  const fileInputRef = useRef(null)

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      setImageFile(file)
      const reader = new FileReader()
      reader.onloadend = () => setImagePreview(reader.result)
      reader.readAsDataURL(file)
    }
  }

  const handleSave = async () => {
    if (!form.name || !form.name.trim()) {
      alert('Proje adı zorunludur.')
      return
    }
    try {
      setIsSaving(true)
      const selectedStatus = STATUS_OPTIONS.find((s) => s.status === form.status)
      // image_path artık bir FileField; görsel değişikliği ayrı bir multipart
      // istekle (imageFile parametresi) yapılıyor. Mevcut URL string'ini JSON
      // gövdesinde geri göndermek DRF'te dosya bekleyen alanda doğrulama
      // hatasına yol açtığı için burada çıkarıyoruz.
      const { image_path, ...formWithoutImage } = form
      await onSave({
        ...formWithoutImage,
        estimated_total_cost: parseMoneyInput(form.estimated_total_cost),
        estimated_total_revenue: parseMoneyInput(form.estimated_total_revenue),
        status_color_hex: selectedStatus?.color ?? form.status_color_hex,
        status_bg_color_hex: selectedStatus?.bg ?? form.status_bg_color_hex,
      }, imageFile)
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
        <div className="modal-body" style={{ display: 'grid', gap: '1.25rem' }}>
          
          {/* Proje Görseli Yükleme */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: '0.5rem' }}>
            <div 
              onClick={() => fileInputRef.current?.click()}
              style={{
                width: '100%',
                height: '160px',
                borderRadius: '12px',
                background: `url(${imagePreview}) center/cover no-repeat`,
                border: '2px dashed var(--color-border)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                position: 'relative',
                overflow: 'hidden'
              }}
            >
              <div style={{
                position: 'absolute',
                bottom: 12,
                right: 12,
                background: 'var(--color-surface)',
                borderRadius: '50%',
                padding: '8px',
                boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                display: 'flex'
              }}>
                <Camera size={18} color="var(--color-text-main)" />
              </div>
            </div>
            <input 
              type="file" 
              accept="image/*" 
              ref={fileInputRef} 
              style={{ display: 'none' }} 
              onChange={handleFileChange} 
            />
            <span style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginTop: '0.5rem' }}>Projeye ait görsel eklemek/değiştirmek için tıklayın</span>
          </div>

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
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <input
                type="text"
                className="form-input"
                style={{ flex: 1 }}
                value={form.location || ''}
                onChange={(e) => setForm({ ...form, location: e.target.value })}
              />
              <button
                type="button"
                className="icon-btn"
                title="Haritadan Seç"
                onClick={() => setMapOpen(true)}
                style={{ width: 44, height: 44, flexShrink: 0 }}
              >
                <LocateFixed size={18} />
              </button>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem', alignItems: 'end' }}>
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

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem', alignItems: 'end' }}>
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

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', alignItems: 'end' }}>
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
              <MoneyInput
                value={form.estimated_total_cost || ''}
                onChange={(v) => setForm({ ...form, estimated_total_cost: v })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Öngörülen Toplam Gelir (₺)</label>
              <MoneyInput
                value={form.estimated_total_revenue || ''}
                onChange={(v) => setForm({ ...form, estimated_total_revenue: v })}
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

      {mapOpen && (
        <MapLocationPicker
          onClose={() => setMapOpen(false)}
          onSelect={(location) => { setForm((f) => ({ ...f, location })); setMapOpen(false) }}
        />
      )}
    </div>,
    document.body,
  )
}
