import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { createPortal } from 'react-dom'
import { Plus, ArrowRight, ChevronRight, CheckCircle, Circle, Edit2, Trash2, X } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num, parseStatusColor, withAlpha15, projectImage } from '../utils'
import ProjectFormModal from '../components/ProjectFormModal'

function DeleteProjectsModal({ count, onClose, onConfirm }) {
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
          <span className="modal-title">Projeleri Sil</span>
          <button className="modal-close" onClick={onClose} title="Kapat"><X size={18} /></button>
        </div>
        <div className="modal-body" style={{ padding: '0.25rem 1.25rem 1.1rem' }}>
          {err && <div className="error-message">{err}</div>}
          <p style={{ color: 'var(--color-text-muted)', fontSize: '0.88rem', margin: 0 }}>
            Seçili {count} projeyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve projelere bağlı tüm veriler silinir.
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

export default function Projects() {
  const navigate = useNavigate()
  const { projects, transactions, addProject, uploadProjectImage, deleteProject, loading, loaded, error } = useData()
  const [createOpen, setCreateOpen] = useState(false)
  const [isEditMode, setIsEditMode] = useState(false)
  const [selectedIds, setSelectedIds] = useState([])
  const [deleteOpen, setDeleteOpen] = useState(false)

  // İşlemleri proje bazında grupla (mobil provider mantığı).
  const txByProject = useMemo(() => {
    const map = new Map()
    for (const t of transactions) {
      const pid = t.project_id
      if (pid == null) continue
      if (!map.has(pid)) map.set(pid, [])
      map.get(pid).push(t)
    }
    return map
  }, [transactions])

  const handleToggleEditMode = () => {
    setIsEditMode(!isEditMode)
    setSelectedIds([])
  }

  const handleToggleSelect = (id, e) => {
    e.stopPropagation()
    setSelectedIds(prev =>
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    )
  }

  const handleDeleteSelected = () => {
    if (selectedIds.length === 0) return
    setDeleteOpen(true)
  }

  const confirmDeleteSelected = async () => {
    for (const id of selectedIds) {
      await deleteProject(id)
    }
    setSelectedIds([])
    setIsEditMode(false)
    setDeleteOpen(false)
  }

  const computeCard = (project) => {
    const list = txByProject.get(project.id) || []
    const totalCost = num(project.estimated_total_cost)
    const totalGider = list.filter((t) => t.type === 'Gider').reduce((s, t) => s + num(t.amount), 0)
    const tahsilat = list.filter((t) => t.type === 'Tahsilat' || t.type === 'Gelir').reduce((s, t) => s + num(t.amount), 0)
    const satis = list.filter((t) => t.type === 'Satış').reduce((s, t) => s + num(t.amount), 0)
    let realizationPercent = totalCost > 0 ? Math.trunc((totalGider / totalCost) * 100) : 0
    if (project.status && project.status.toLowerCase() === 'tamamlandı') {
      realizationPercent = 100
    }
    const kar = satis - totalCost
    const karPercent = satis > 0 ? Math.trunc((kar / satis) * 100) : 0
    return { totalCost, tahsilat, satis, realizationPercent, karPercent }
  }

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  if (error && !loaded) {
    return (
      <div className="summary-box">
        <div className="empty-state">
          <span className="text-danger" style={{ fontWeight: 700 }}>{error}</span>
        </div>
      </div>
    )
  }

  return (
    <div>
      {projects.length > 0 && (
        <div className="section-header" style={{ marginTop: 0 }}>
          <span
            className="section-title"
            style={{ color: isEditMode ? 'var(--color-danger, #ef4444)' : 'var(--color-primary)' }}
          >
            {isEditMode ? `${selectedIds.length} SEÇİLİ` : 'DEVAM EDEN PROJELER'}
          </span>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            {isEditMode ? (
              <>
                <button
                  className="btn-inline-text text-danger"
                  onClick={handleDeleteSelected}
                  disabled={selectedIds.length === 0}
                  style={{
                    color: 'var(--color-danger, #ef4444)',
                    opacity: selectedIds.length === 0 ? 0.5 : 1,
                    padding: '6px',
                    minWidth: 'auto',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}
                  title="Seçilenleri Sil"
                >
                  <Trash2 size={16} />
                </button>
                <button
                  className="btn-inline-text"
                  onClick={handleToggleEditMode}
                  style={{
                    padding: '6px',
                    minWidth: 'auto',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}
                  title="Vazgeç"
                >
                  <X size={16} />
                </button>
              </>
            ) : (
              <>
                <button
                  className="btn-inline-text"
                  onClick={handleToggleEditMode}
                  style={{
                    padding: '6px',
                    minWidth: 'auto',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}
                  title="Düzenle"
                >
                  <Edit2 size={16} />
                </button>
                <button className="btn-inline-text" onClick={() => setCreateOpen(true)}>
                  <Plus size={16} /> Yeni Proje
                </button>
              </>
            )}
          </div>
        </div>
      )}

      {projects.length === 0 ? (
        <div className="empty-state" style={{ padding: '5rem 0' }}>
          <div className="empty-circle" onClick={() => setCreateOpen(true)} style={{ cursor: 'pointer' }}>
            <Plus size={40} />
          </div>
          <span style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>
            Henüz bir projeniz yok
          </span>
        </div>
      ) : (
        <div className="projects-grid">
          {projects.map((project) => {
            const { totalCost, tahsilat, satis, realizationPercent, karPercent } = computeCard(project)
            const statusColor = parseStatusColor(project.status_color_hex)
            const isZero = realizationPercent === 0
            const percentColor = isZero ? 'var(--color-text-muted)' : 'var(--color-success)'
            const imgUrl = projectImage(project)
            const isSelected = selectedIds.includes(project.id)

            return (
              <div
                key={project.id}
                className="project-card"
                style={isEditMode && isSelected ? { border: '2px solid var(--color-danger, #ef4444)' } : {}}
                onClick={(e) => {
                  if (isEditMode) {
                    handleToggleSelect(project.id, e)
                  } else {
                    navigate(`/dashboard/projects/${project.id}`)
                  }
                }}
              >
                {/* Üst satır */}
                <div className="pcard-top">
                  {isEditMode ? (
                    <div
                      className="project-thumb"
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        backgroundColor: 'var(--color-background-alt, #f9fafb)',
                        color: isSelected ? 'var(--color-danger, #ef4444)' : 'var(--color-text-muted, #9ca3af)',
                        border: `1px solid ${isSelected ? 'var(--color-danger, #ef4444)' : 'var(--color-border, #e5e7eb)'}`,
                        borderRadius: '8px'
                      }}
                    >
                      {isSelected ? (
                        <CheckCircle size={24} style={{ fill: 'var(--color-danger, #ef4444)', color: '#white' }} />
                      ) : (
                        <Circle size={24} />
                      )}
                    </div>
                  ) : (
                    <div className="project-thumb" style={{ backgroundImage: `url(${imgUrl})` }} />
                  )}

                  <div className="pcard-info">
                    <span
                      className="status-badge-inline"
                      style={{ color: statusColor, backgroundColor: withAlpha15(statusColor) }}
                    >
                      {project.status || '—'}
                    </span>
                    <div className="project-title">{project.name}</div>
                    <div className="pcard-cost-label">Toplam Maliyet</div>
                    <div className="pcard-cost-value">{formatCurrency(totalCost)}</div>
                  </div>

                  <div className="pcard-realization">
                    <span className="pcard-mini-label">Gerçekleşme</span>
                    <span className="pcard-percent" style={{ color: percentColor }}>%{realizationPercent}</span>
                    <div className="pcard-progress">
                      <div
                        className="pcard-progress-fill"
                        style={{ width: `${Math.min(realizationPercent, 100)}%`, background: percentColor }}
                      />
                    </div>
                  </div>
                </div>

                <div className="pcard-divider" />

                {/* Orta satır: Tahsilat / Satış / Kâr */}
                <div className="pcard-stats">
                  <div className="pcard-stat">
                    <span className="pcard-mini-label">Tahsilat</span>
                    <span className="pcard-stat-value">{formatCurrency(tahsilat)}</span>
                  </div>
                  <div className="pcard-stat">
                    <span className="pcard-mini-label">Satış</span>
                    <span className="pcard-stat-value">{formatCurrency(satis)}</span>
                  </div>
                  <div className="pcard-stat">
                    <span className="pcard-mini-label">Kâr</span>
                    <span className="pcard-stat-value" style={{ color: karPercent > 0 ? 'var(--color-success)' : 'var(--color-text-muted)' }}>
                      %{karPercent}
                    </span>
                  </div>
                </div>

                {/* Detay linki */}
                <div className="pcard-detail-link">
                  <span>{isEditMode ? 'Seç' : 'Detay'}</span>
                  <ChevronRight size={14} />
                </div>
              </div>
            )
          })}
        </div>
      )}

      {createOpen && (
        <ProjectFormModal
          onClose={() => setCreateOpen(false)}
          onSave={async (projectData, imageFile) => {
            const created = await addProject(projectData)
            if (imageFile && created?.id) {
              await uploadProjectImage(created.id, imageFile)
            }
          }}
        />
      )}

      {deleteOpen && (
        <DeleteProjectsModal
          count={selectedIds.length}
          onClose={() => setDeleteOpen(false)}
          onConfirm={confirmDeleteSelected}
        />
      )}
    </div>
  )
}
