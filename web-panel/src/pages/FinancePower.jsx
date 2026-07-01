import { Shield, Plus, Building, CreditCard, PiggyBank, ArrowRight } from 'lucide-react'

export default function FinancePower() {
  const formatCurrency = (val) => {
    return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(val)
  }

  const fTotal = 18250000.0
  const bchTotal = 8000000.0
  const cardLimitTotal = 500000.0
  const esnekTotal = 1750000.0

  return (
    <div>
      <div className="page-header-banner total-card-green" style={{ background: 'var(--color-success)', color: '#ffffff' }}>
        <div>
          <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.8)' }}>TOPLAM FİNANSMAN GÜCÜ</div>
          <div className="total-card-value" style={{ color: '#ffffff' }}>{formatCurrency(fTotal)}</div>
        </div>
        <div className="total-card-icon">
          <Shield size={36} color="#ffffff" />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', alignItems: 'start', marginTop: '1.75rem' }}>
        
        {/* SOL SÜTUN: Limitler */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          
          {/* BCH */}
          <div>
            <div className="section-header">
              <span className="section-title">KULLANILABİLİR BCH</span>
              <button className="btn-inline-text">
                <Plus size={16} /> Yeni Limit
              </button>
            </div>
            <div className="list-group">
              <div className="list-item">
                <div className="list-icon-box"><Building size={20} className="text-info" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">Halkbank</div>
                  <div className="list-item-subtitle">Kullanılabilir</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(5000000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
              <div className="list-item">
                <div className="list-icon-box"><Building size={20} className="text-danger" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">Ziraat</div>
                  <div className="list-item-subtitle">Kullanılabilir</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(3000000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
            </div>
          </div>

          {/* KART LİMİTLERİ */}
          <div>
            <div className="section-header">
              <span className="section-title">KART LİMİTLERİ</span>
              <button className="btn-inline-text">
                <Plus size={16} /> Yeni Limit
              </button>
            </div>
            <div className="list-group">
              <div className="list-item">
                <div className="list-icon-box"><CreditCard size={20} className="text-danger" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">Ziraat Bankkart</div>
                  <div className="list-item-subtitle">Kullanılabilir</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(300000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
              <div className="list-item">
                <div className="list-icon-box"><CreditCard size={20} className="text-primary" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">Finansbank CardFinans</div>
                  <div className="list-item-subtitle">Kullanılabilir</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(200000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
            </div>
          </div>

          {/* ESNEK HESAPLAR */}
          <div>
            <div className="section-header">
              <span className="section-title">ESNEK HESAPLAR</span>
              <button className="btn-inline-text">
                <Plus size={16} /> Yeni Limit
              </button>
            </div>
            <div className="list-group">
              <div className="list-item">
                <div className="list-icon-box"><PiggyBank size={20} className="text-info" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">Halkbank</div>
                  <div className="list-item-subtitle">Kullanılabilir</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(1000000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
              <div className="list-item">
                <div className="list-icon-box"><PiggyBank size={20} className="text-danger" /></div>
                <div className="list-item-content">
                  <div className="list-item-title">Ziraat</div>
                  <div className="list-item-subtitle">Kullanılabilir</div>
                </div>
                <div className="list-item-value-box">
                  <div className="list-item-value">{formatCurrency(750000)}</div>
                </div>
                <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
              </div>
            </div>
          </div>

        </div>

        {/* SAĞ SÜTUN: ÖZET */}
        <div>
          <div className="section-header">
            <span className="section-title">ÖZET</span>
          </div>
          <div className="summary-box">
            <div className="summary-row">
              <span className="summary-label">Toplam BCH</span>
              <span className="summary-value">{formatCurrency(bchTotal)}</span>
            </div>
            <div className="summary-row">
              <span className="summary-label">Toplam Kart Limitleri</span>
              <span className="summary-value">{formatCurrency(cardLimitTotal)}</span>
            </div>
            <div className="summary-row">
              <span className="summary-label">Toplam Esnek Hesaplar</span>
              <span className="summary-value">{formatCurrency(esnekTotal)}</span>
            </div>
            <div className="summary-total-row">
              <span className="summary-total-label" style={{ color: 'var(--color-primary)' }}>TOPLAM LİMİTLER</span>
              <span className="summary-total-value" style={{ color: 'var(--color-primary)' }}>{formatCurrency(bchTotal + cardLimitTotal + esnekTotal)}</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  )
}
