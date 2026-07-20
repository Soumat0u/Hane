import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Shield, Plus, PiggyBank, ArrowRight } from 'lucide-react'
import { useData } from '../context/DataContext'
import { num } from '../utils'
import BankLogo from '../components/BankLogo'
import AccountFormModal from '../components/AccountFormModal'

export default function FinancePower() {
  const navigate = useNavigate()
  const { accounts, addAccount } = useData()
  const [newType, setNewType] = useState(null)

  const formatCurrency = (val) => {
    return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(val)
  }

  const creditCardAccounts = useMemo(() => accounts.filter((a) => a.type === 'Kredi Kartı'), [accounts])
  const bchAccounts = useMemo(() => accounts.filter((a) => a.type === 'BCH'), [accounts])
  const esnekAccounts = useMemo(() => accounts.filter((a) => a.type === 'Esnek'), [accounts])

  const bchTotal = useMemo(() => bchAccounts.reduce((s, a) => s + num(a.available_limit), 0), [bchAccounts])
  const cardLimitTotal = useMemo(
    () => creditCardAccounts.reduce((s, a) => s + num(a.available_limit), 0),
    [creditCardAccounts],
  )
  const esnekTotal = useMemo(() => esnekAccounts.reduce((s, a) => s + num(a.available_limit), 0), [esnekAccounts])
  const fTotal = bchTotal + cardLimitTotal + esnekTotal

  const goToAccount = (account) => navigate(`/dashboard/accounts/${account.id}`)

  return (
    <div>
      <div className="page-header-banner total-card-green" style={{ background: 'var(--banner-finance)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>TOPLAM FİNANSMAN GÜCÜ</div>
          <div className="total-card-value" style={{ color: 'var(--banner-text)' }}>{formatCurrency(fTotal)}</div>
        </div>
        <div className="total-card-icon">
          <Shield size={36} color="var(--banner-text)" />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '2rem', alignItems: 'start', marginTop: '1.75rem' }}>
        
        {/* SOL SÜTUN: Limitler */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          
          {/* BCH */}
          <div>
            <div className="section-header">
              <span className="section-title">KULLANILABİLİR BCH</span>
              <button className="btn-inline-text" onClick={() => setNewType('BCH')}>
                <Plus size={16} /> Yeni BCH Limiti
              </button>
            </div>
            {bchAccounts.length === 0 ? (
              <div className="summary-box">
                <div className="empty-state" style={{ padding: '1.5rem 0' }}>
                  <span>Kayıtlı BCH limiti bulunamadı.</span>
                </div>
              </div>
            ) : (
              <div className="list-group">
                {bchAccounts.map((a) => (
                  <div className="list-item" key={a.id} onClick={() => goToAccount(a)} style={{ cursor: 'pointer' }}>
                    <div className="list-icon-box"><BankLogo bankName={a.bank_logo_painter || a.name} width={34} height={34} /></div>
                    <div className="list-item-content">
                      <div className="list-item-title">{a.name}</div>
                      <div className="list-item-subtitle">Kullanılabilir</div>
                    </div>
                    <div className="list-item-value-box">
                      <div className="list-item-value">{formatCurrency(num(a.available_limit))}</div>
                    </div>
                    <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* KART LİMİTLERİ */}
          <div>
            <div className="section-header">
              <span className="section-title">KART LİMİTLERİ</span>
              <button className="btn-inline-text" onClick={() => setNewType('Kredi Kartı')}>
                <Plus size={16} /> Yeni Kredi Kartı
              </button>
            </div>
            {creditCardAccounts.length === 0 ? (
              <div className="summary-box">
                <div className="empty-state" style={{ padding: '1.5rem 0' }}>
                  <span>Kayıtlı kredi kartı bulunamadı.</span>
                </div>
              </div>
            ) : (
              <div className="list-group">
                {creditCardAccounts.map((a, i) => {
                  const totalLimit = num(a.credit_limit)
                  const remainingLimit = num(a.available_limit)
                  const usedLimit = totalLimit - remainingLimit
                  const usedPct = totalLimit > 0 ? Math.min(Math.max(usedLimit / totalLimit, 0), 1) * 100 : 0
                  return (
                    <div
                      key={a.id}
                      onClick={() => goToAccount(a)}
                      style={{
                        cursor: 'pointer',
                        padding: '1rem',
                        borderBottom: i < creditCardAccounts.length - 1 ? '1px solid var(--color-border)' : 'none',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.75rem' }}>
                        <BankLogo bankName={a.bank_logo_painter || a.name} width={30} height={30} />
                        <span style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--color-text)' }}>{a.name}</span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
                        <div>
                          <div style={{ fontSize: '0.7rem', fontWeight: 600, color: 'var(--color-text-muted)' }}>Toplam Limit</div>
                          <div style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--color-text)' }}>{formatCurrency(totalLimit)}</div>
                        </div>
                        <div>
                          <div style={{ fontSize: '0.7rem', fontWeight: 600, color: 'var(--color-text-muted)' }}>Kullanılan</div>
                          <div style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--color-text)' }}>{formatCurrency(usedLimit)}</div>
                        </div>
                        <div>
                          <div style={{ fontSize: '0.7rem', fontWeight: 600, color: 'var(--color-text-muted)' }}>Kalan Limit</div>
                          <div style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--color-primary)' }}>{formatCurrency(remainingLimit)}</div>
                        </div>
                      </div>
                      <div style={{ height: 6, borderRadius: 3, background: 'var(--color-border)', overflow: 'hidden' }}>
                        <div style={{ height: '100%', width: `${usedPct}%`, borderRadius: 3, background: 'var(--color-primary)' }} />
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* ESNEK HESAPLAR */}
          <div>
            <div className="section-header">
              <span className="section-title">ESNEK HESAPLAR</span>
              <button className="btn-inline-text" onClick={() => setNewType('Esnek')}>
                <Plus size={16} /> Yeni Esnek Hesap
              </button>
            </div>
            {esnekAccounts.length === 0 ? (
              <div className="summary-box">
                <div className="empty-state" style={{ padding: '1.5rem 0' }}>
                  <span>Kayıtlı esnek hesap bulunamadı.</span>
                </div>
              </div>
            ) : (
              <div className="list-group">
                {esnekAccounts.map((a) => (
                  <div className="list-item" key={a.id} onClick={() => goToAccount(a)} style={{ cursor: 'pointer' }}>
                    <div className="list-icon-box"><PiggyBank size={20} className="text-info" /></div>
                    <div className="list-item-content">
                      <div className="list-item-title">{a.name}</div>
                      <div className="list-item-subtitle">Kullanılabilir</div>
                    </div>
                    <div className="list-item-value-box">
                      <div className="list-item-value">{formatCurrency(num(a.available_limit))}</div>
                    </div>
                    <ArrowRight size={14} className="text-muted" style={{ marginLeft: '1rem' }} />
                  </div>
                ))}
              </div>
            )}
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

      {newType && (
        <AccountFormModal
          initialType={newType}
          lockType
          onClose={() => setNewType(null)}
          onSave={addAccount}
        />
      )}
    </div>
  )
}
