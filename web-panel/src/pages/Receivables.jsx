import { ArrowDownToLine, Hammer } from 'lucide-react'

export default function Receivables() {
  return (
    <div>
      <div className="page-header-banner" style={{ background: 'var(--banner-receivables)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>ALACAKLAR</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: 'var(--banner-text)' }}>Tüm Alacaklar ve Tahsilatlar</div>
        </div>
        <div className="total-card-icon">
          <ArrowDownToLine size={34} color="#ffffff" />
        </div>
      </div>

      <div className="summary-box">
        <div className="empty-state">
          <Hammer size={40} className="text-warning" />
          <div>
            <div style={{ fontWeight: 700, color: 'var(--color-text-main)', marginBottom: '0.25rem' }}>Bu sayfa yapım aşamasında</div>
            <div style={{ fontSize: '0.9rem' }}>Alacak kayıtları ve tahsilat planları yakında burada listelenecek.</div>
          </div>
        </div>
      </div>
    </div>
  )
}
