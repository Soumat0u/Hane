import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, X, SearchX, ChevronRight, Building2, Wallet, CheckCircle, Circle } from 'lucide-react'
import { useData } from '../context/DataContext'
import { formatCurrency, num } from '../utils'
import { txVisuals, INCOME_TYPES } from '../txVisuals'

const dateFmt = (raw) => {
  if (!raw) return ''
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' })
}

const dayOnly = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate())

export default function Transactions() {
  const navigate = useNavigate()
  const { transactions, projects, loading, loaded, deleteTransaction } = useData()

  const [search, setSearch] = useState('')
  const [type, setType] = useState('Tümü')
  const [proje, setProje] = useState('Tümü')
  const [kategori, setKategori] = useState('Tümü')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [visibleCount, setVisibleCount] = useState(10)
  const [isEditMode, setIsEditMode] = useState(false)
  const [selectedIds, setSelectedIds] = useState([])

  const projectNames = useMemo(() => {
    const m = {}
    projects.forEach((p) => { if (p.id != null) m[p.id] = p.name })
    return m
  }, [projects])

  const typeOptions = useMemo(
    () => ['Tümü', ...new Set(transactions.map((t) => t.type).filter(Boolean))],
    [transactions],
  )
  const projeOptions = useMemo(() => ['Tümü', ...Object.values(projectNames)], [projectNames])
  const kategoriOptions = useMemo(
    () => ['Tümü', ...new Set(transactions.map((t) => t.category).filter(Boolean))],
    [transactions],
  )

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

  const handleDeleteSelected = async () => {
    if (selectedIds.length === 0) return
    const confirmed = window.confirm(`${selectedIds.length} işlemi silmek istediğinize emin misiniz?`)
    if (!confirmed) return
    try {
      for (const id of selectedIds) {
        await deleteTransaction(id)
      }
      setSelectedIds([])
      setIsEditMode(false)
    } catch (err) {
      alert("İşlemler silinirken bir hata oluştu.")
    }
  }

  const filtered = useMemo(() => {
    const arr = transactions.filter((t) => {
      if (type !== 'Tümü' && t.type !== type) return false
      if (proje !== 'Tümü') {
        const name = t.project_id != null ? projectNames[t.project_id] : null
        if (name !== proje) return false
      }
      if (kategori !== 'Tümü' && t.category !== kategori) return false
      if (dateFrom || dateTo) {
        const d = t.date ? new Date(t.date) : null
        if (!d || Number.isNaN(d.getTime())) return false
        const day = dayOnly(d)
        if (dateFrom && day < dayOnly(new Date(dateFrom))) return false
        if (dateTo && day > dayOnly(new Date(dateTo))) return false
      }
      if (search) {
        const hay = `${t.description || ''} ${t.category || ''} ${t.contact_name || ''} ${t.source_name || ''} ${t.dest_name || ''}`.toLowerCase()
        if (!hay.includes(search.toLowerCase())) return false
      }
      return true
    })
    arr.sort((a, b) => {
      const da = a.date ? new Date(a.date) : null
      const db = b.date ? new Date(b.date) : null
      if (!da && !db) return 0
      if (!da) return 1
      if (!db) return -1
      return db - da
    })
    return arr
  }, [transactions, type, proje, kategori, dateFrom, dateTo, search, projectNames])

  const toplamGelir = useMemo(
    () => filtered.filter((t) => INCOME_TYPES.has(t.type)).reduce((s, t) => s + num(t.amount), 0),
    [filtered],
  )
  const toplamGider = useMemo(
    () => filtered.filter((t) => t.type === 'Gider').reduce((s, t) => s + num(t.amount), 0),
    [filtered],
  )
  const net = toplamGelir - toplamGider

  const hasActiveFilter = type !== 'Tümü' || proje !== 'Tümü' || kategori !== 'Tümü' || !!dateFrom || !!dateTo
  const clearFilters = () => {
    setType('Tümü'); setProje('Tümü'); setKategori('Tümü'); setDateFrom(''); setDateTo('')
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
      <div className="page-header-banner" style={{ background: 'var(--banner-dashboard)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>İŞLEMLER</div>
          <div className="total-card-value" style={{ fontSize: '1.75rem', color: 'var(--banner-text)' }}>Hesap Hareketleri</div>
        </div>
        <div className="total-card-icon">
          <Wallet size={36} color="#ffffff" />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', alignItems: 'start', marginTop: '1.75rem' }}>
        
        {/* SOL SÜTUN: Liste */}
        <div>
          <div className="section-header">
            <span
              className="section-title"
              style={{ color: isEditMode ? 'var(--color-danger, #ef4444)' : 'inherit' }}
            >
              {isEditMode ? `${selectedIds.length} SEÇİLİ` : `HAREKETLER (${filtered.length})`}
            </span>
            <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
              {isEditMode ? (
                <>
                  <button
                    className="btn-inline-text text-danger"
                    onClick={handleDeleteSelected}
                    disabled={selectedIds.length === 0}
                    style={{ color: 'var(--color-danger, #ef4444)', opacity: selectedIds.length === 0 ? 0.5 : 1, padding: 0 }}
                  >
                    Seçilenleri Sil
                  </button>
                  <button className="btn-inline-text" onClick={handleToggleEditMode} style={{ padding: 0 }}>
                    Vazgeç
                  </button>
                </>
              ) : (
                <>
                  {hasActiveFilter && (
                    <button className="btn-inline-text" onClick={clearFilters} style={{ padding: 0 }}>
                      <X size={16} /> Filtreyi Temizle
                    </button>
                  )}
                  {filtered.length > 0 && (
                    <button className="btn-inline-text" onClick={handleToggleEditMode} style={{ padding: 0 }}>
                      Düzenle
                    </button>
                  )}
                </>
              )}
            </div>
          </div>
          
          {filtered.length === 0 ? (
            <div className="empty-state" style={{ padding: '4rem 0' }}>
              <SearchX size={44} />
              <span style={{ fontWeight: 600 }}>
                {transactions.length === 0 ? 'Henüz işlem yok' : 'Seçilen filtrelere uygun işlem yok'}
              </span>
            </div>
          ) : (
            <>
              <div className="list-group">
                {filtered.slice(0, visibleCount).map((t) => {
                  const { color, Icon } = txVisuals(t.type)
                  const title = t.description || t.category || t.type
                  const projectName = t.project_id != null ? projectNames[t.project_id] : null
                  const account = t.source_name || t.dest_name
                  const isSelected = selectedIds.includes(t.id)
                  
                  return (
                    <div
                      className="list-item"
                      key={t.id}
                      style={{
                        cursor: 'pointer',
                        border: isEditMode && isSelected ? '2px solid var(--color-danger, #ef4444)' : '1px solid var(--color-border)',
                        backgroundColor: isEditMode && isSelected ? 'var(--color-danger-light, rgba(239, 68, 68, 0.08))' : 'inherit'
                      }}
                      onClick={(e) => {
                        if (isEditMode) {
                          handleToggleSelect(t.id, e)
                        } else {
                          navigate(`/dashboard/transactions/${t.id}`)
                        }
                      }}
                    >
                      {isEditMode ? (
                        <div
                          className="list-icon-box"
                          style={{
                            background: 'transparent',
                            color: isSelected ? 'var(--color-danger, #ef4444)' : 'var(--color-text-muted, #9ca3af)',
                            border: `1px solid ${isSelected ? 'var(--color-danger, #ef4444)' : 'var(--color-border, #e5e7eb)'}`,
                            borderRadius: '8px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            width: '40px',
                            height: '40px',
                            minWidth: '40px'
                          }}
                        >
                          {isSelected ? (
                            <CheckCircle size={20} style={{ fill: 'var(--color-danger, #ef4444)', color: '#white' }} />
                          ) : (
                            <Circle size={20} />
                          )}
                        </div>
                      ) : (
                        <div className="list-icon-box" style={{ background: `color-mix(in srgb, ${color} 15%, transparent)`, color: color }}>
                          <Icon size={20} />
                        </div>
                      )}
                      <div className="list-item-content">
                        <div className="list-item-title">{title}</div>
                        <div className="list-item-subtitle">
                          <span style={{ color }}>{(t.type || '').toUpperCase()}</span>
                          {t.contact_name && ` • ${t.contact_name}`}
                          {projectName && ` • ${projectName}`}
                          {account && ` • ${account}`}
                        </div>
                      </div>
                      <div className="list-item-value-box">
                        <div className="list-item-value" style={{ color }}>{formatCurrency(t.amount)}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', textAlign: 'right', marginTop: '0.2rem' }}>
                          {dateFmt(t.date)}
                        </div>
                      </div>
                      <ChevronRight size={16} className="text-muted" style={{ marginLeft: '1rem' }} />
                    </div>
                  )
                })}
              </div>
              
              {filtered.length > visibleCount && (
                <button 
                  className="btn-ghost" 
                  onClick={() => setVisibleCount(prev => prev + 10)}
                  style={{ width: '100%', marginTop: '1rem', display: 'flex', justifyContent: 'center', gap: '0.5rem' }}
                >
                  Daha Fazla Göster ({(filtered.length - visibleCount) > 10 ? 10 : (filtered.length - visibleCount)} / {filtered.length - visibleCount})
                </button>
              )}
            </>
          )}
        </div>

        {/* SAĞ SÜTUN: Filtre & Özet */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          
          {/* FİLTRE KUTUSU */}
          <div>
            <div className="section-header">
              <span className="section-title">FİLTRELE</span>
            </div>
            <div className="summary-box" style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div className="input-group" style={{ marginBottom: 0 }}>
                <div style={{ position: 'relative' }}>
                  <Search size={18} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
                  <input className="input-field" style={{ paddingLeft: '2.5rem' }} value={search} onChange={(e) => setSearch(e.target.value)} placeholder="İşlem ara..." />
                </div>
              </div>
              
              <div className="input-group" style={{ marginBottom: 0 }}>
                <label className="input-label">TÜR</label>
                <select className="input-field" value={type} onChange={(e) => setType(e.target.value)}>
                  {typeOptions.map((o) => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>

              <div className="input-group" style={{ marginBottom: 0 }}>
                <label className="input-label">PROJE</label>
                <select className="input-field" value={proje} onChange={(e) => setProje(e.target.value)}>
                  {projeOptions.map((o) => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>

              <div className="input-group" style={{ marginBottom: 0 }}>
                <label className="input-label">KATEGORİ</label>
                <select className="input-field" value={kategori} onChange={(e) => setKategori(e.target.value)}>
                  {kategoriOptions.map((o) => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>

              <div className="input-group" style={{ marginBottom: 0 }}>
                <label className="input-label">TARİH ARALIĞI</label>
                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                  <input className="input-field" type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
                  <span style={{ color: 'var(--color-text-muted)' }}>–</span>
                  <input className="input-field" type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
                </div>
              </div>
            </div>
          </div>

          {/* ÖZET KUTUSU */}
          <div>
            <div className="section-header">
              <span className="section-title">ÖZET</span>
            </div>
            <div className="summary-box">
              <div className="summary-row">
                <span className="summary-label">Gelir Toplamı</span>
                <span className="summary-value text-success">{formatCurrency(toplamGelir)}</span>
              </div>
              <div className="summary-row">
                <span className="summary-label">Gider Toplamı</span>
                <span className="summary-value text-danger">{formatCurrency(toplamGider)}</span>
              </div>
              <div className="summary-total-row">
                <span className="summary-total-label" style={{ color: net >= 0 ? 'var(--color-success)' : 'var(--color-danger)' }}>NET DURUM</span>
                <span className="summary-total-value" style={{ color: net >= 0 ? 'var(--color-success)' : 'var(--color-danger)' }}>
                  {formatCurrency(net)}
                </span>
              </div>
            </div>
          </div>

        </div>

      </div>
    </div>
  )
}
