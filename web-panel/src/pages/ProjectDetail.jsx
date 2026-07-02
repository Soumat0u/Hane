import { useMemo, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts'
import {
  ArrowLeft, Pencil, Plus, MapPin, Building2, ChevronRight, X, Trash2,
  Truck, Grid3x3, BrickWall, Zap, Droplet, HardHat, Construction, Wrench,
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
    projects, transactions, budgetLines, contacts, loading, loaded, error,
    updateProject, deleteProject, addBudgetLine, updateBudgetLine, deleteBudgetLine,
    addSale, addReceivable,
  } = useData()
  const [selectedCategory, setSelectedCategory] = useState('Tümü')
  const [budgetModal, setBudgetModal] = useState(null) // null | { line: existing|null }
  const [budgetForm, setBudgetForm] = useState({ category: '', budgeted_amount: '' })
  const [savingBudget, setSavingBudget] = useState(false)
  const [saleModalOpen, setSaleModalOpen] = useState(false)
  const [expenseModalOpen, setExpenseModalOpen] = useState(false)

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

  const projectBudgetLines = useMemo(
    () => budgetLines.filter((b) => String(b.project) === String(id)),
    [budgetLines, id],
  )

  const openAddBudget = () => {
    setBudgetForm({ category: '', budgeted_amount: '' })
    setBudgetModal({ line: null })
  }

  const openEditBudget = (line) => {
    setBudgetForm({ category: line.category || '', budgeted_amount: line.budgeted_amount || '' })
    setBudgetModal({ line })
  }

  const handleSaveBudget = async () => {
    try {
      setSavingBudget(true)
      const body = {
        project: project.id,
        category: budgetForm.category,
        budgeted_amount: budgetForm.budgeted_amount,
      }
      if (budgetModal.line) {
        await updateBudgetLine(budgetModal.line.id, body)
      } else {
        await addBudgetLine(body)
      }
      setBudgetModal(null)
    } catch {
      alert('Bütçe kalemi kaydedilemedi.')
    } finally {
      setSavingBudget(false)
    }
  }

  const handleDeleteBudget = async (line) => {
    if (!window.confirm(`"${line.category}" bütçe kalemini silmek istediğinize emin misiniz?`)) return
    try {
      await deleteBudgetLine(line.id)
    } catch {
      alert('Bütçe kalemi silinemedi.')
    }
  }

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
          
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '1.5rem', marginTop: '1.5rem' }}>
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

      {/* Bütçe */}
      <div className="detail-section-head" style={{ marginTop: '2rem' }}>
        <h2 className="detail-section-title">BÜTÇE</h2>
        <button className="btn-inline-text" style={{ color: 'var(--color-primary)' }} onClick={openAddBudget}>
          <Plus size={16} /> Bütçe Kalemi Ekle
        </button>
      </div>

      {projectBudgetLines.length === 0 ? (
        <div className="summary-box">
          <div className="empty-state" style={{ padding: '1.5rem 0' }}>
            <span>Henüz bütçe kalemi eklenmedi.</span>
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {projectBudgetLines.map((line) => {
            const budgeted = num(line.budgeted_amount)
            const actual = num(line.actual_amount)
            const usedPct = budgeted > 0 ? Math.min(actual / budgeted, 1) : 0
            const overBudget = budgeted > 0 && actual > budgeted
            const barColor = overBudget ? 'var(--color-danger)' : 'var(--color-primary)'

            return (
              <div
                key={line.id}
                className="summary-box"
                style={{ padding: '1rem 1.25rem', cursor: 'pointer', border: overBudget ? '1px solid var(--color-danger)' : undefined }}
                onClick={() => openEditBudget(line)}
              >
                <div style={{ display: 'flex', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span style={{ flex: 1, fontWeight: 700, fontSize: '0.95rem' }}>{line.category}</span>
                  {overBudget && (
                    <span style={{
                      marginRight: '0.5rem', padding: '2px 8px', borderRadius: 8,
                      fontSize: '0.7rem', fontWeight: 700, color: 'var(--color-danger)', background: 'var(--color-dangerBg)',
                    }}>
                      Aşıldı
                    </span>
                  )}
                  <button
                    className="icon-btn"
                    style={{ width: 28, height: 28 }}
                    onClick={(e) => { e.stopPropagation(); handleDeleteBudget(line) }}
                    title="Sil"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: 'var(--color-text-muted)', marginBottom: '0.5rem' }}>
                  <span>{formatCurrency(actual)} / {formatCurrency(budgeted)}</span>
                  <span style={{ fontWeight: 700, color: barColor }}>%{(usedPct * 100).toFixed(0)}</span>
                </div>
                <div className="pcard-progress">
                  <div className="pcard-progress-fill" style={{ width: `${usedPct * 100}%`, background: barColor }} />
                </div>
              </div>
            )
          })}
        </div>
      )}

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
      {isEditing && (
        <ProjectFormModal
          project={project}
          onClose={() => setIsEditing(false)}
          onSave={(body) => updateProject(project.id, body)}
          onDelete={handleDelete}
        />
      )}
      {budgetModal && (
        <div className="modal-overlay" onClick={() => !savingBudget && setBudgetModal(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2 className="modal-title">{budgetModal.line ? 'Bütçe Kalemini Düzenle' : 'Bütçe Kalemi Ekle'}</h2>
              <button className="modal-close" onClick={() => setBudgetModal(null)} disabled={savingBudget}>
                <X size={20} />
              </button>
            </div>
            <div className="modal-body" style={{ display: 'grid', gap: '1rem' }}>
              <div className="form-group">
                <label className="form-label">Kategori</label>
                <input
                  type="text"
                  className="form-input"
                  value={budgetForm.category}
                  onChange={(e) => setBudgetForm({ ...budgetForm, category: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Planlanan Tutar</label>
                <input
                  type="number"
                  className="form-input"
                  value={budgetForm.budgeted_amount}
                  onChange={(e) => setBudgetForm({ ...budgetForm, budgeted_amount: e.target.value })}
                />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-secondary" onClick={() => setBudgetModal(null)} disabled={savingBudget}>
                İptal
              </button>
              <button
                className="btn-primary"
                onClick={handleSaveBudget}
                disabled={savingBudget || !budgetForm.category}
              >
                {savingBudget ? <span className="loader"></span> : 'Kaydet'}
              </button>
            </div>
          </div>
        </div>
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
