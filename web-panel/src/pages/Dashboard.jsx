import { Wallet, Receipt, ArrowDownToLine, Shield, TrendingUp, TrendingDown, ArrowUpRight, ArrowDownRight } from 'lucide-react'
import { LineChart, Line, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts'
import { useNavigate } from 'react-router-dom'
import { useData } from '../context/DataContext'
import { projectImage } from '../utils'

export default function Dashboard() {
  const navigate = useNavigate()
  const { projects: allProjects, transactions: allTransactions, accounts, loans, receivables, loading, loaded } = useData()

  const formatCurrency = (val) => {
    return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(val)
  }

  // GERÇEK VERİLER — veritabanından hesaplanır (mobil ile aynı mantık)
  const kasa = (accounts || []).reduce((sum, a) => sum + (Number(a.balance) || 0), 0)
  const borclar = (loans || []).reduce((sum, l) => sum + (Number(l.remaining) || Number(l.total_payable) || 0), 0)
  const alacaklar = (receivables || []).reduce((sum, r) => {
    const total = Number(r.total_amount) || 0
    const collected = Number(r.collected_amount) || 0
    return sum + (total - collected)
  }, 0)
  const finansmanGucu = kasa + (accounts || []).reduce((sum, a) => sum + (Number(a.credit_limit) || 0), 0)
  const netPozisyon = kasa + alacaklar - borclar

  const metricCards = [
    { title: 'KASA', value: kasa, icon: <Wallet size={24} />, color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.2)', path: '/dashboard/accounts' },
    { title: 'BORÇLAR', value: borclar, icon: <Receipt size={24} />, color: '#ef4444', bg: 'rgba(239, 68, 68, 0.2)', path: '/dashboard/debts' },
    { title: 'ALACAKLAR', value: alacaklar, icon: <ArrowDownToLine size={24} />, color: '#10b981', bg: 'rgba(16, 185, 129, 0.2)', path: '/dashboard/receivables' },
    { title: 'FİNANSMAN GÜCÜ', value: finansmanGucu, icon: <Shield size={24} />, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.2)', path: '/dashboard/finance-power' },
  ]

  // Net pozisyon grafiği (Sparkline) — son 7 günün gerçek kasa bakiyesi yok, basit trend
  const sparklineData = [
    { value: netPozisyon * 0.85 }, { value: netPozisyon * 0.90 }, { value: netPozisyon * 0.88 },
    { value: netPozisyon * 0.95 }, { value: netPozisyon * 0.92 }, { value: netPozisyon * 0.98 }, { value: netPozisyon }
  ]

  // Nakit Akışı (Aylık) — son 6 ayın GERÇEK işlemlerinden hesaplanır
  const cashFlowData = (() => {
    const now = new Date()
    const months = []
    const monthNames = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara']
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      const year = d.getFullYear()
      const month = d.getMonth()
      const txns = (allTransactions || []).filter(t => {
        if (!t.date) return false
        const td = new Date(t.date)
        return td.getFullYear() === year && td.getMonth() === month
      })
      const gelir = txns.filter(t => t.type === 'Gelir' || t.type === 'Tahsilat' || t.type === 'Satış').reduce((s, t) => s + (Number(t.amount) || 0), 0)
      const gider = txns.filter(t => t.type === 'Gider' || t.type === 'Ödeme').reduce((s, t) => s + (Number(t.amount) || 0), 0)
      months.push({ name: monthNames[month], Gelir: gelir, Gider: gider })
    }
    return months
  })()

  // Projelerim (Son 3 Proje)
  const projects = allProjects ? [...allProjects].sort((a, b) => b.id - a.id).slice(0, 3) : []

  // Son Hareketler (Son 5 Hareket)
  const recentTransactions = allTransactions ? [...allTransactions].sort((a, b) => {
    const da = a.date ? new Date(a.date) : null
    const db = b.date ? new Date(b.date) : null
    if (!da && !db) return 0
    if (!da) return 1
    if (!db) return -1
    return db - da
  }).slice(0, 5) : []

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
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>GENEL BAKIŞ</div>
          <div className="total-card-value" style={{ fontSize: '1.75rem', color: 'var(--banner-text)' }}>Finansal Durum</div>
        </div>
      </div>

      <div className="dashboard-content-grid" style={{ gridTemplateColumns: '1fr', gap: '2rem' }}>

        {/* 4'lü Grid Metrik Kartları */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.5rem' }}>
          {metricCards.map((card, idx) => (
            <div
              key={idx}
              className="project-card"
              onClick={() => navigate(card.path)}
              style={{
                display: 'flex', flexDirection: 'column', padding: '1.5rem', cursor: 'pointer',
                transition: 'transform 0.2s', backgroundColor: card.bg, border: 'none'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
                <div style={{
                  width: '48px', height: '48px', borderRadius: '12px',
                  backgroundColor: card.color, color: '#ffffff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                  {card.icon}
                </div>
              </div>
              <div className="project-stat-label" style={{ marginBottom: '0.25rem', fontSize: '0.875rem', color: card.color, fontWeight: '700' }}>{card.title}</div>
              <div className="project-stat-value" style={{ fontSize: '1.5rem', color: 'var(--color-text-main)' }}>{formatCurrency(card.value)}</div>
            </div>
          ))}
        </div>

        {/* NET POZİSYON KARTI (Degrade + Sparkline) */}
        <div className="content-card net-position-card" style={{ padding: '2rem', display: 'flex', alignItems: 'center', border: 'none', borderRadius: '16px' }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '0.875rem', fontWeight: '700', letterSpacing: '1px', marginBottom: '0.5rem', opacity: 0.8 }}>NET POZİSYON</div>
            <div style={{ fontSize: '2rem', fontWeight: '800' }}>
              {formatCurrency(netPozisyon)}
            </div>
          </div>
          <div style={{ flex: 1, height: '80px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={sparklineData}>
                <Line type="monotone" dataKey="value" stroke="currentColor" strokeWidth={3} dot={false} style={{ opacity: 0.8 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* NAKİT AKIŞI GRAFİĞİ */}
        <div>
          <div className="section-header">
            <span className="section-title">NAKİT AKIŞI (AYLIK)</span>
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#10b981' }}></div>
                <span style={{ fontSize: '0.875rem', color: 'var(--color-text-main)' }}>Gelir</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ width: '12px', height: '12px', borderRadius: '50%', backgroundColor: '#ef4444' }}></div>
                <span style={{ fontSize: '0.875rem', color: 'var(--color-text-main)' }}>Gider</span>
              </div>
            </div>
          </div>
          <div className="summary-box" style={{ padding: '2rem', height: '350px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={cashFlowData} margin={{ top: 10, right: 10, left: 20, bottom: 0 }} barGap={6} barCategoryGap="35%">
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--color-border)" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: 'var(--color-text-muted)' }} dy={10} />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: 'var(--color-text-muted)' }}
                  tickFormatter={(value) => `${value >= 1000 ? (value / 1000) + 'k' : value}`}
                  dx={-10}
                />
                <Tooltip
                  cursor={{ fill: 'rgba(128, 128, 128, 0.1)' }}
                  contentStyle={{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: '8px' }}
                  formatter={(value) => formatCurrency(value)}
                />
                <Bar dataKey="Gelir" fill="#10b981" radius={[4, 4, 0, 0]} maxBarSize={40} />
                <Bar dataKey="Gider" fill="#ef4444" radius={[4, 4, 0, 0]} maxBarSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem' }}>

          {/* PROJELERİM */}
          <div>
            <div className="section-header">
              <span className="section-title">PROJELERİM</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {projects.map((project) => {
                const list = allTransactions.filter(t => t.project_id === project.id)
                const totalCost = Number(project.estimated_total_cost) || 0
                const totalGider = list.filter((t) => t.type === 'Gider').reduce((s, t) => s + (Number(t.amount) || 0), 0)
                const satis = list.filter((t) => t.type === 'Satış').reduce((s, t) => s + (Number(t.amount) || 0), 0)
                const realizationPercent = totalCost > 0 ? (totalGider / totalCost) * 100 : 0
                const kar = satis - totalCost
                const statusColor = project.status_color_hex || '#3b82f6'
                const imgUrl = projectImage(project)

                return (
                  <div key={project.id} className="project-card" onClick={() => navigate(`/dashboard/projects/${project.id}`)} style={{ cursor: 'pointer' }}>
                    <div className="project-card-header">
                      <div className="project-image" style={{ width: '48px', height: '48px', borderRadius: '8px', backgroundColor: 'var(--color-border)', backgroundImage: `url(${imgUrl})`, backgroundSize: 'cover', backgroundPosition: 'center' }}></div>
                      <div className="project-info">
                        <div className="project-title">{project.name}</div>
                        <div className="status-badge-inline" style={{ color: statusColor, backgroundColor: `${statusColor}22`, marginTop: '0.25rem' }}>
                          {project.status || 'Aktif'}
                        </div>
                      </div>
                    </div>
                    <div className="project-stats-grid" style={{ gridTemplateColumns: '1fr 1fr' }}>
                      <div className="project-stat-col">
                        <span className="project-stat-label">Gerçekleşme</span>
                        <span className="project-stat-value text-success">%{realizationPercent.toFixed(0)}</span>
                      </div>
                      <div className="project-stat-col">
                        <span className="project-stat-label">Kâr</span>
                        <span className="project-stat-value">{formatCurrency(kar)}</span>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* SON HAREKETLER */}
          <div>
            <div className="section-header">
              <span className="section-title">SON HAREKETLER</span>
            </div>
            <div className="list-group">
              {recentTransactions.map(t => {
                const date = t.date ? new Intl.DateTimeFormat('tr-TR', { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date(t.date)) : ''
                const isIncome = t.type === 'Gelir' || t.type === 'Tahsilat'
                const isExpense = t.type === 'Gider' || t.type === 'Ödeme'
                const displayType = isIncome ? 'Gelir' : (isExpense ? 'Gider' : t.type)
                
                return (
                  <div key={t.id} className="list-item" onClick={() => navigate(`/dashboard/transactions/${t.id}`)} style={{ cursor: 'pointer' }}>
                    <div className="list-icon-box">
                      {isIncome ? (
                        <ArrowDownRight size={20} className="text-success" />
                      ) : (
                        <ArrowUpRight size={20} className="text-danger" />
                      )}
                    </div>
                    <div className="list-item-content">
                      <div className="list-item-title">{t.category || t.description || t.type}</div>
                      <div className="list-item-subtitle">{t.contact_name || (t.project_id ? `Proje ID: ${t.project_id}` : '')}</div>
                    </div>
                    <div className="list-item-value-box">
                      <div className={`list-item-value ${isIncome ? 'text-success' : 'text-danger'}`}>
                        {isIncome ? '+' : '-'}{formatCurrency(t.amount)}
                      </div>
                      <div className="list-item-subvalue" style={{ color: 'var(--color-text-muted)' }}>{date}</div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

        </div>

      </div>
    </div>
  )
}
