import { Plus, Wallet, Banknote, ArrowRight } from 'lucide-react'

export default function Accounts() {
  const formatCurrency = (val) => {
    return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(val)
  }

  const kasaTotal = 750000.00
  const totalBankalar = 700000.00
  const totalNakit = 50000.00

  return (
    <div>
      <div className="page-header-banner total-card-green" style={{ background: 'var(--banner-accounts)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>TOPLAM KASA</div>
          <div className="total-card-value" style={{ color: 'var(--banner-text)' }}>{formatCurrency(kasaTotal)}</div>
        </div>
        <div className="total-card-icon">
          <Wallet size={36} color="var(--banner-text)" />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', alignItems: 'start' }}>
        
        {/* SOL SÜTUN: Bankalar & Nakit */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          {/* BANKALAR */}
          <div>
            <div className="section-header">
              <span className="section-title">BANKALAR</span>
              <button className="btn-inline-text">
                <Plus size={16} /> Yeni İşlem
              </button>
            </div>
            <div className="list-group">
              <div className="list-item">
                <div className="list-icon-box">
                  <Banknote size={20} className="text-info" />
                </div>
                <div className="list-item-content">
                  <div className="list-item-title">Halkbank</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(500000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
              <div className="list-item">
                <div className="list-icon-box">
                  <Banknote size={20} className="text-danger" />
                </div>
                <div className="list-item-content">
                  <div className="list-item-title">Ziraat</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(200000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
            </div>
          </div>

          {/* NAKİT */}
          <div>
            <div className="section-header">
              <span className="section-title">NAKİT</span>
              <button className="btn-inline-text">
                <Plus size={16} /> Yeni İşlem
              </button>
            </div>
            <div className="list-group">
              <div className="list-item">
                <div className="list-icon-box">
                  <Banknote size={20} className="text-success" />
                </div>
                <div className="list-item-content">
                  <div className="list-item-title">Merkez Kasa</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(50000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
            </div>
          </div>
        </div>

        {/* SAĞ SÜTUN: Özet */}
        <div>
          <div className="section-header">
            <span className="section-title">ÖZET</span>
          </div>
          <div className="summary-box">
            <div className="summary-row">
              <span className="summary-label">Toplam Bankalar</span>
              <span className="summary-value">{formatCurrency(totalBankalar)}</span>
            </div>
            <div className="summary-row">
              <span className="summary-label">Nakit</span>
              <span className="summary-value">{formatCurrency(totalNakit)}</span>
            </div>
            <div className="summary-total-row">
              <span className="summary-total-label" style={{ color: 'var(--color-primary)' }}>TOPLAM KASA</span>
              <span className="summary-total-value" style={{ color: 'var(--color-primary)' }}>{formatCurrency(kasaTotal)}</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  )
}
