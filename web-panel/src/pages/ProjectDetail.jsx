import { useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts'
import {
  ArrowLeft, Pencil, Plus, MapPin, Building2, ChevronRight,
  Truck, Grid3x3, BrickWall, Zap, Droplet, HardHat, Construction, Wrench,
  FileText, UploadCloud, Trash2,
} from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, formatNumber, num, projectImage } from '../utils'
import SaleFormModal from '../components/SaleFormModal'
import ProjectFormModal from '../components/ProjectFormModal'
import NewTransactionFormModal from '../components/NewTransactionFormModal'

const CATEGORY_COLORS = {
  'Beton': '#0F172A',
  'Demir': '#3B82F6',
  'Duvar': '#10B981',
  'Kalıp & İskele': '#8B5CF6',
  'Hafriyat': '#10B981',
  'Elektrik': '#F59E0B',
  'Sıhhi Tesisat': '#F43F5E',
  'İşçilik': '#CBD5E1',
  'Genel Gider': '#64748b',
}
const FALLBACK_COLORS = ['#032b5e', '#6366f1', '#0ea5e9', '#14b8a6', '#f97316', '#ec4899', '#84cc16']

const isImageFile = (url) => /\.(png|jpe?g|gif|webp|bmp|svg)$/i.test(url || '')

function categoryIcon(category) {
  switch ((category || '').toLowerCase()) {
    case 'beton': return Truck
    case 'demir': return Grid3x3
    case 'duvar': return BrickWall
    case 'elektrik': return Zap
    case 'sıhhi tesisat': return Droplet
    case 'işçilik': return HardHat
    case 'kalıp': return Construction
    case 'nakliye': return Truck
    default: return Wrench
  }
}

function formatDate(raw) {
  if (!raw) return '-'
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

export default function ProjectDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const {
    projects, transactions, contacts, projectDocuments, loading, loaded, error,
    updateProject, deleteProject,
    addSale, addReceivable,
    addProjectDocument, deleteProjectDocument, renameProjectDocument,
  } = useData()
  const [selectedCategory, setSelectedCategory] = useState('Tümü')
  const [saleModalOpen, setSaleModalOpen] = useState(false)
  const [expenseModalOpen, setExpenseModalOpen] = useState(false)
  const [uploadingDoc, setUploadingDoc] = useState(false)

  const project = useMemo(
    () => projects.find((p) => String(p.id) === String(id)) || null,
    [projects, id],
  )

  const [isEditing, setIsEditing] = useState(false)

  const handleEditClick = () => {
    if (project) setIsEditing(true)
  }

  const handleDelete = async () => {
    try {
      await deleteProject(project.id)
      navigate('/dashboard/projects')
    } catch (err) {
      alert('Hata: Proje silinemedi.')
    }
  }

  const projectTransactions = useMemo(
    () => transactions.filter((t) => String(t.project_id) === String(id)),
    [transactions, id],
  )

  const documents = useMemo(
    () => projectDocuments.filter((d) => String(d.project) === String(id)),
    [projectDocuments, id],
  )

  const handleFileSelected = async (e) => {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file || !project) return
    setUploadingDoc(true)
    try {
      await addProjectDocument(project.id, file.name, file)
    } catch {
      alert('Belge yüklenemedi.')
    } finally {
      setUploadingDoc(false)
    }
  }

  const handleDeleteDocument = async (doc) => {
    if (!window.confirm(`"${doc.name}" belgesini silmek istediğinize emin misiniz?`)) return
    try {
      await deleteProjectDocument(doc.id)
    } catch {
      alert('Belge silinemedi.')
    }
  }

  const handleRenameDocument = async (doc) => {
    const newName = window.prompt('Belge adı:', doc.name || '')
    if (newName === null) return
    const trimmed = newName.trim()
    if (!trimmed || trimmed === doc.name) return
    try {
      await renameProjectDocument(doc.id, trimmed)
    } catch {
      alert('Belge adı güncellenemedi.')
    }
  }

  const harcamalar = useMemo(
    () => projectTransactions.filter((t) => t.type === 'Gider'),
    [projectTransactions],
  )

  const totalGider = useMemo(() => harcamalar.reduce((s, t) => s + num(t.amount), 0), [harcamalar])

  const buAyHarcama = useMemo(() => {
    const now = new Date()
    return harcamalar.reduce((s, t) => {
      const d = new Date(t.date)
      if (Number.isNaN(d.getTime())) return s
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear() ? s + num(t.amount) : s
    }, 0)
  }, [harcamalar])

  const categories = useMemo(() => {
    const uniq = [...new Set(harcamalar.map((t) => t.category).filter(Boolean))].sort()
    return ['Tümü', ...uniq]
  }, [harcamalar])

  const filtered = useMemo(
    () => (selectedCategory === 'Tümü' ? harcamalar : harcamalar.filter((t) => t.category === selectedCategory)),
    [harcamalar, selectedCategory],
  )

  const spendingData = useMemo(() => {
    const sums = new Map()
    for (const t of harcamalar) {
      const key = t.category || 'Genel Gider'
      sums.set(key, (sums.get(key) || 0) + num(t.amount))
    }
    let fi = 0
    const arr = [...sums.entries()].map(([name, value]) => ({
      name,
      value,
      amount: formatCurrency(value),
      percentage: totalGider > 0 ? (value / totalGider) * 100 : 0,
      color: CATEGORY_COLORS[name] || FALLBACK_COLORS[fi++ % FALLBACK_COLORS.length],
    }))
    arr.sort((a, b) => b.percentage - a.percentage)
    return arr
  }, [harcamalar, totalGider])

  if (loading && !loaded) {
    return (
      <div className="page-loader">
        <span className="loader" style={{ borderTopColor: 'var(--color-accent)', borderColor: 'var(--color-border)', borderTopWidth: 3, width: 32, height: 32 }} />
      </div>
    )
  }

  if (!project) {
    return (
      <div>
        <button className="btn-inline-text" onClick={() => navigate(-1)} style={{ marginBottom: '1rem' }}>
          <ArrowLeft size={16} /> Geri
        </button>
        <div className="summary-box">
          <div className="empty-state">
            <span className="text-danger" style={{ fontWeight: 700 }}>{error || 'Proje bulunamadı.'}</span>
          </div>
        </div>
      </div>
    )
  }

  const kalanButce = num(project.estimated_total_cost) - totalGider

  return (
    <div>
      {/* Sayfa başlığı */}
      <div className="detail-topbar">
        <button className="icon-btn" onClick={() => navigate(-1)} title="Geri">
          <ArrowLeft size={20} />
        </button>
        <h1 className="detail-title">{project.name}</h1>
        <button className="icon-btn" title="Düzenle" onClick={handleEditClick}>
          <Pencil size={18} />
        </button>
      </div>

      {/* Hero kart */}
      <div className="detail-hero">
        <div className="detail-hero-img" style={{ backgroundImage: `url(${projectImage(project)})` }} />
        <div className="detail-hero-info" style={{ flex: 1, paddingRight: '1rem' }}>
          <div className="detail-hero-name-row">
            <span className="detail-hero-name">{project.name}</span>
            <span className="detail-code-badge">{project.project_code || '—'}</span>
          </div>
          
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '1.75rem', marginTop: '1.75rem' }}>
            <div className="detail-stat" style={{ alignItems: 'flex-start' }}>
              <span className="detail-stat-label">Lokasyon</span>
              <span className="detail-stat-value" style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                <MapPin size={14} className="text-muted" /> {project.location || '-'}
              </span>
            </div>
            <div className="detail-stat" style={{ alignItems: 'flex-start' }}>
              <span className="detail-stat-label">Proje Tipi</span>
              <span className="detail-stat-value" style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                <Building2 size={14} className="text-muted" /> {project.project_type || '-'}
              </span>
            </div>
            <div className="detail-stat" style={{ alignItems: 'flex-start' }}>
              <span className="detail-stat-label">Pafta</span>
              <span className="detail-stat-value">{project.pafta || '-'}</span>
            </div>
            <div className="detail-stat" style={{ alignItems: 'flex-start' }}>
              <span className="detail-stat-label">Parsel</span>
              <span className="detail-stat-value">{project.parsel || '-'}</span>
            </div>
            <div className="detail-stat" style={{ alignItems: 'flex-start' }}>
              <span className="detail-stat-label">Alan (m²)</span>
              <span className="detail-stat-value">{formatNumber(project.area_sq_meters)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Harcamalar başlığı */}
      <div className="detail-section-head">
        <h2 className="detail-section-title">HARCAMALAR</h2>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn-dark" onClick={() => setExpenseModalOpen(true)}>
            <Plus size={16} /> Yeni Harcama Ekle
          </button>
          <button className="btn-dark" onClick={() => setSaleModalOpen(true)}>
            <Plus size={16} /> Yeni Satış
          </button>
        </div>
      </div>

      {/* Filtre çipleri */}
      {categories.length > 1 && (
        <div className="filter-chips">
          {categories.map((cat) => (
            <button
              key={cat}
              className={`filter-chip ${selectedCategory === cat ? 'active' : ''}`}
              onClick={() => setSelectedCategory(cat)}
            >
              {cat}
            </button>
          ))}
        </div>
      )}

      {/* Harcama tablosu */}
      <div className="expense-table">
        <div className="expense-row expense-header">
          <span className="col-category">KATEGORİ</span>
          <span className="col-desc">AÇIKLAMA</span>
          <span className="col-supplier">TEDARİKÇİ</span>
          <span className="col-amount">TUTAR</span>
          <span className="col-date">TARİH</span>
          <span className="col-chevron" />
        </div>

        {filtered.length === 0 ? (
          <div className="empty-state" style={{ padding: '2.5rem 0' }}>
            <span>Bu kategoriye ait harcama bulunamadı.</span>
          </div>
        ) : (
          filtered.map((t, i) => {
            const Icon = categoryIcon(t.category)
            return (
              <div className="expense-row" key={t.id ?? i} onClick={() => navigate(`/dashboard/transactions/${t.id}`)} style={{ cursor: 'pointer' }}>
                <span className="col-category">
                  <span className="cat-icon-box"><Icon size={16} /></span>
                  <span className="cat-name">{t.category || '-'}</span>
                </span>
                <span className="col-desc">{t.description || '-'}</span>
                <span className="col-supplier">{t.contact_name || '-'}</span>
                <span className="col-amount">{formatCurrency(t.amount)}</span>
                <span className="col-date">{formatDate(t.date)}</span>
                <span className="col-chevron"><ChevronRight size={16} /></span>
              </div>
            )
          })
        )}
      </div>

      {/* Özet kartları */}
      <div className="detail-summary">
        <div className="detail-summary-col">
          <span className="detail-summary-label">Toplam Harcama</span>
          <span className="detail-summary-value">{formatCurrency(totalGider)}</span>
        </div>
        <div className="detail-summary-divider" />
        <div className="detail-summary-col">
          <span className="detail-summary-label">Bu Ay Harcama</span>
          <span className="detail-summary-value">{formatCurrency(buAyHarcama)}</span>
        </div>
        <div className="detail-summary-divider" />
        <div className="detail-summary-col">
          <span className="detail-summary-label">Kalan Bütçe</span>
          <span className="detail-summary-value text-success">{formatCurrency(kalanButce)}</span>
        </div>
      </div>

      {/* Harcama Dağılımı */}
      <div className="spending-card" style={{ marginTop: '2rem' }}>
        <div className="spending-head">
          <h2 className="detail-section-title" style={{ margin: 0 }}>Harcama Dağılımı</h2>
          <span className="btn-inline-text" style={{ color: 'var(--color-primary)', cursor: 'default' }}>
            Tümünü Gör <ChevronRight size={14} />
          </span>
        </div>

        {spendingData.length === 0 ? (
          <p className="text-muted" style={{ marginTop: '1rem' }}>Harcama verisi bulunamadı.</p>
        ) : (
          <div className="spending-body">
            <div className="donut-wrap">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={spendingData}
                    dataKey="value"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    innerRadius={54}
                    outerRadius={72}
                    paddingAngle={2}
                    stroke="none"
                  >
                    {spendingData.map((entry) => (
                      <Cell key={entry.name} fill={entry.color} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="donut-center">
                <span className="donut-center-label">Toplam</span>
                <span className="donut-center-value">{formatCurrency(totalGider)}</span>
              </div>
            </div>

            <div className="spending-legend">
              {spendingData.map((item) => (
                <div className="spending-legend-row" key={item.name}>
                  <span className="legend-dot" style={{ background: item.color }} />
                  <span className="legend-name">{item.name}</span>
                  <span className="legend-amount">{item.amount}</span>
                  <span className="legend-pct">%{item.percentage.toFixed(1)}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Belgeler */}
      <div className="detail-section-head" style={{ marginTop: '2rem' }}>
        <h2 className="detail-section-title">BELGELER</h2>
        <label className="btn-inline-text" style={{ color: 'var(--color-primary)', cursor: uploadingDoc ? 'default' : 'pointer' }}>
          {uploadingDoc ? <span className="loader" /> : <UploadCloud size={16} />}
          {uploadingDoc ? 'Yükleniyor...' : 'Belge Ekle'}
          <input type="file" hidden disabled={uploadingDoc} onChange={handleFileSelected} />
        </label>
      </div>

      {documents.length === 0 ? (
        <div className="summary-box">
          <div className="empty-state" style={{ padding: '1.5rem 0' }}>
            <span>Henüz belge eklenmedi.</span>
          </div>
        </div>
      ) : (
        <div className="document-grid">
          {documents.map((doc) => {
            const isImage = isImageFile(doc.file)
            return (
              <a
                href={doc.file}
                target="_blank"
                rel="noreferrer"
                className="document-card"
                key={doc.id}
                style={{ cursor: doc.file ? 'pointer' : 'default' }}
                onClick={(e) => { if (!doc.file) e.preventDefault() }}
              >
                <div className="document-card-preview">
                  {isImage ? (
                    <img src={doc.file} alt={doc.name || 'Belge'} />
                  ) : (
                    <FileText size={40} className="text-primary" />
                  )}
                </div>
                <div
                  className="document-card-info"
                  style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.4rem' }}
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); handleRenameDocument(doc) }}
                  title="Adı değiştir"
                >
                  <div style={{ minWidth: 0 }}>
                    <div className="document-card-title">{doc.name || 'Belge'}</div>
                    <div className="document-card-subtitle">{formatDate(doc.uploaded_at)}</div>
                  </div>
                  <Pencil size={12} className="text-muted" style={{ flexShrink: 0 }} />
                </div>
                <button
                  className="document-card-delete"
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); handleDeleteDocument(doc) }}
                  title="Sil"
                >
                  <Trash2 size={14} />
                </button>
              </a>
            )
          })}
        </div>
      )}

      {isEditing && (
        <ProjectFormModal
          project={project}
          onClose={() => setIsEditing(false)}
          onSave={(body) => updateProject(project.id, body)}
          onDelete={handleDelete}
        />
      )}
      {saleModalOpen && project && (
        <SaleFormModal
          projectId={project.id}
          projectName={project.name}
          contacts={contacts}
          onClose={() => setSaleModalOpen(false)}
          onSaveSale={addSale}
          onSaveReceivable={addReceivable}
        />
      )}

      {expenseModalOpen && project && (
        <NewTransactionFormModal
          type="Ödeme"
          initialProjectId={project.id}
          onClose={() => setExpenseModalOpen(false)}
        />
      )}
    </div>
  )
}
