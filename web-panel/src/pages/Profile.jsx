import { useState, useRef } from 'react'
import {
  User, Copy, Check, Phone, Mail, MapPin, Plus, Pencil, AlertTriangle,
  CreditCard, Building, ChevronDown, ChevronUp, Globe, Camera
} from 'lucide-react'
import { useData } from '../context/DataContext'
import BankLogo from '../components/BankLogo'
import AccountFormModal from '../components/AccountFormModal'
import { isProfileComplete } from '../utils'

export default function Profile() {
  const {
    companyProfile,
    updateCompanyProfile,
    uploadCompanyLogo,
    accounts,
    addAccount,
    updateAccount,
    loading
  } = useData()

  const [copiedField, setCopiedField] = useState(null)
  const [isEditing, setIsEditing] = useState(false)
  const [formData, setFormData] = useState({})
  const fileInputRef = useRef(null)
  const [accountModal, setAccountModal] = useState(null) // { type, lockType, account? }
  
  const handleFileChange = async (e) => {
    const file = e.target.files[0]
    if (file) {
      try {
        await uploadCompanyLogo(file)
      } catch (err) {
        alert('Fotoğraf yüklenirken bir hata oluştu.')
      }
    }
  }
  
  // Collapse states (default true for web since we have more space)
  const [expandedSections, setExpandedSections] = useState({
    banks: true,
    cards: true,
    address: true,
    contact: true
  })

  const toggleSection = (section) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section]
    }))
  }

  const handleCopy = (text, fieldName) => {
    navigator.clipboard.writeText(text)
    setCopiedField(fieldName)
    setTimeout(() => setCopiedField(null), 2000)
  }

  const startEdit = () => {
    setFormData({
      company_name: companyProfile?.company_name || '',
      tax_office: companyProfile?.tax_office || '',
      tax_number: companyProfile?.tax_number || '',
      commercial_registry: companyProfile?.commercial_registry || '',
      mersis_no: companyProfile?.mersis_no || '',
      address_title: companyProfile?.address_title || '',
      address_line1: companyProfile?.address_line1 || '',
      address_line2: companyProfile?.address_line2 || '',
      city: companyProfile?.city || '',
      country: companyProfile?.country || '',
      phone1: companyProfile?.phone1 || '',
      email: companyProfile?.email || '',
      website: companyProfile?.website || '',
    })
    setIsEditing(true)
  }

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const handleSave = async (e) => {
    e.preventDefault()
    try {
      await updateCompanyProfile(formData)
      setIsEditing(false)
    } catch (err) {
      alert('Güncelleme sırasında bir hata oluştu.')
    }
  }

  if (loading && !companyProfile) {
    return <div style={{ padding: '2rem', textAlign: 'center' }}>Yükleniyor...</div>
  }

  const bankAccounts = accounts.filter(a => a.type === 'Banka')
  const cardAccounts = accounts.filter(a => a.type === 'Kredi Kartı')

  return (
    <div>
      {/* BANNER */}
      <div className="page-header-banner" style={{ background: 'var(--banner-dashboard)', color: 'var(--banner-text)' }}>
        <div>
          <div className="total-card-label" style={{ color: 'var(--banner-label)' }}>PROFİL</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem', color: 'var(--banner-text)' }}>Şirket Profili & Hesaplar</div>
        </div>
        <div className="total-card-icon" style={{ opacity: 0.85 }}>
          <User size={34} color="#ffffff" />
        </div>
      </div>

      {!isProfileComplete(companyProfile) && (
        <div style={{
          display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.9rem 1.1rem',
          background: 'color-mix(in srgb, var(--color-warning) 12%, transparent)',
          border: '1px solid color-mix(in srgb, var(--color-warning) 40%, transparent)',
          borderRadius: 'var(--radius-md)', marginBottom: '1.5rem',
        }}>
          <AlertTriangle size={20} color="var(--color-warning)" style={{ flexShrink: 0 }} />
          <span style={{ flex: 1, fontSize: '0.85rem', color: 'var(--color-text-main)' }}>
            Firma bilgileriniz eksik. Faturalar ve belgelerde doğru görünmesi için tamamlayın.
          </span>
          <button
            className="btn-inline-text"
            style={{ color: 'var(--color-warning)', fontWeight: 700 }}
            onClick={startEdit}
          >
            Doldur
          </button>
        </div>
      )}

      {/* GRID STRUCTURE */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(380px, 1fr))', gap: '1.5rem', alignItems: 'start' }}>
        
        {/* SOL SÜTUN: Şirket Bilgileri, Adres, İletişim */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Şirket Bilgileri Kartı */}
          <div className="summary-box" style={{ padding: '1.5rem' }}>
            {isEditing ? (
              <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--color-text-main)', marginBottom: '0.25rem' }}>Şirket Bilgilerini Düzenle</h3>
                
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Şirket Adı</label>
                    <input type="text" name="company_name" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.company_name} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Vergi Dairesi</label>
                    <input type="text" name="tax_office" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.tax_office} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Vergi No</label>
                    <input type="text" name="tax_number" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.tax_number} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Ticari Sicil No</label>
                    <input type="text" name="commercial_registry" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.commercial_registry} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Mersis No</label>
                    <input type="text" name="mersis_no" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.mersis_no} onChange={handleInputChange} />
                  </div>
                </div>

                <h4 style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--color-text-main)', marginTop: '0.5rem' }}>Adres Bilgileri</h4>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem', gridColumn: 'span 2' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Adres Başlığı</label>
                    <input type="text" name="address_title" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.address_title} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem', gridColumn: 'span 2' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Adres Satırı 1</label>
                    <input type="text" name="address_line1" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.address_line1} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem', gridColumn: 'span 2' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Adres Satırı 2</label>
                    <input type="text" name="address_line2" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.address_line2} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Şehir</label>
                    <input type="text" name="city" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.city} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Ülke</label>
                    <input type="text" name="country" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.country} onChange={handleInputChange} />
                  </div>
                </div>

                <h4 style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--color-text-main)', marginTop: '0.5rem' }}>İletişim Bilgileri</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Telefon</label>
                    <input type="text" name="phone1" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.phone1} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>E-posta</label>
                    <input type="email" name="email" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.email} onChange={handleInputChange} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Web Sitesi</label>
                    <input type="text" name="website" className="search-input" style={{ width: '100%', maxWidth: 'none' }} value={formData.website} onChange={handleInputChange} />
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                  <button type="submit" className="btn-dark" style={{ background: 'var(--color-accent)' }}>Kaydet</button>
                  <button type="button" className="filter-chip" onClick={() => setIsEditing(false)}>İptal</button>
                </div>
              </form>
            ) : (
              <div>
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '1.25rem', marginBottom: '1.5rem', flexWrap: 'wrap' }}>
                  {/* Logo Frame */}
                  <div style={{ position: 'relative', width: '64px', height: '64px' }}>
                    <div 
                      onClick={() => fileInputRef.current?.click()}
                      style={{
                        width: '64px',
                        height: '64px',
                        borderRadius: '50%',
                        background: companyProfile?.logo
                          ? `url(${companyProfile.logo.startsWith('/media/') 
                              ? (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' ? 'http://localhost:8000' : 'https://web-production-77031.up.railway.app') + companyProfile.logo
                              : companyProfile.logo}) center/cover no-repeat`
                          : 'linear-gradient(135deg, var(--color-accent), var(--color-primary-light))',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#ffffff',
                        fontSize: '1.5rem',
                        fontWeight: 900,
                        flexShrink: 0,
                        cursor: 'pointer',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.1)'
                      }}>
                      {!companyProfile?.logo && (companyProfile?.company_name ? companyProfile.company_name.charAt(0).toUpperCase() : 'H')}
                    </div>
                    <div 
                      onClick={() => fileInputRef.current?.click()}
                      style={{
                        position: 'absolute',
                        bottom: '-4px',
                        right: '-4px',
                        background: 'var(--color-surface)',
                        borderRadius: '50%',
                        padding: '4px',
                        cursor: 'pointer',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center'
                      }}>
                      <Camera size={14} color="var(--color-text-main)" />
                    </div>
                    <input 
                      type="file" 
                      accept="image/*" 
                      ref={fileInputRef} 
                      style={{ display: 'none' }} 
                      onChange={handleFileChange} 
                    />
                  </div>
                  
                  <div style={{ flex: 1, minWidth: '200px' }}>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                      {companyProfile?.company_name || 'Şirket Adı Belirtilmemiş'}
                    </h2>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem', marginTop: '0.75rem' }}>
                      <div style={{ display: 'flex', fontSize: '0.8rem' }}>
                        <span style={{ width: '120px', fontWeight: 700, color: 'var(--color-text-muted)' }}>Vergi Dairesi</span>
                        <span style={{ color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.tax_office || '-'}</span>
                      </div>
                      <div style={{ display: 'flex', fontSize: '0.8rem' }}>
                        <span style={{ width: '120px', fontWeight: 700, color: 'var(--color-text-muted)' }}>Vergi No</span>
                        <span style={{ color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.tax_number || '-'}</span>
                      </div>
                      <div style={{ display: 'flex', fontSize: '0.8rem' }}>
                        <span style={{ width: '120px', fontWeight: 700, color: 'var(--color-text-muted)' }}>Ticari Sicil No</span>
                        <span style={{ color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.commercial_registry || '-'}</span>
                      </div>
                      <div style={{ display: 'flex', fontSize: '0.8rem' }}>
                        <span style={{ width: '120px', fontWeight: 700, color: 'var(--color-text-muted)' }}>Mersis No</span>
                        <span style={{ color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.mersis_no || '-'}</span>
                      </div>
                    </div>
                  </div>
                </div>
                <button className="btn-dark" style={{ width: '100%' }} onClick={startEdit}>Profili Düzenle</button>
              </div>
            )}
          </div>

          {/* Adres Bilgileri */}
          <div className="summary-box" style={{ padding: '0', overflow: 'hidden' }}>
            <div 
              onClick={() => toggleSection('address')} 
              style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', 
                padding: '1.25rem 1.5rem', cursor: 'pointer', background: 'var(--color-surface-hover)'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                <MapPin size={20} />
                <span>Adres Bilgileri</span>
              </div>
              {expandedSections.address ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
            </div>
            
            {expandedSections.address && (
              <div style={{ padding: '1.25rem 1.5rem', borderTop: '1px solid var(--color-border)', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--color-text-muted)', marginBottom: '0.2rem' }}>
                      {companyProfile?.address_title || 'İş Adresi'}
                    </div>
                    <div style={{ fontSize: '0.9rem', color: 'var(--color-text-main)', fontWeight: 600 }}>
                      {companyProfile?.address_line1 ? (
                        <>
                          {companyProfile.address_line1} {companyProfile.address_line2}<br />
                          {companyProfile.city} / {companyProfile.country}
                        </>
                      ) : 'Adres Belirtilmemiş'}
                    </div>
                  </div>
                  {companyProfile?.address_line1 && (
                    <button className="icon-btn" onClick={() => handleCopy(`${companyProfile.address_line1} ${companyProfile.address_line2} ${companyProfile.city}/${companyProfile.country}`, 'addr')} style={{ width: '32px', height: '32px', border: 'none' }}>
                      {copiedField === 'addr' ? <Check size={16} color="var(--color-success)" /> : <Copy size={16} />}
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* İletişim Bilgileri */}
          <div className="summary-box" style={{ padding: '0', overflow: 'hidden' }}>
            <div 
              onClick={() => toggleSection('contact')} 
              style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', 
                padding: '1.25rem 1.5rem', cursor: 'pointer', background: 'var(--color-surface-hover)'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                <Phone size={20} />
                <span>İletişim Bilgileri</span>
              </div>
              {expandedSections.contact ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
            </div>
            
            {expandedSections.contact && (
              <div style={{ padding: '1.25rem 1.5rem', borderTop: '1px solid var(--color-border)', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Phone size={18} color="var(--color-text-muted)" />
                    <div>
                      <div style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Telefon</div>
                      <div style={{ fontSize: '0.9rem', color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.phone1 || '-'}</div>
                    </div>
                  </div>
                  {companyProfile?.phone1 && (
                    <button className="icon-btn" onClick={() => handleCopy(companyProfile.phone1, 'phone')} style={{ width: '32px', height: '32px', border: 'none' }}>
                      {copiedField === 'phone' ? <Check size={16} color="var(--color-success)" /> : <Copy size={16} />}
                    </button>
                  )}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderTop: '1px solid var(--color-surface-variant)', paddingTop: '0.75rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Mail size={18} color="var(--color-text-muted)" />
                    <div>
                      <div style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>E-posta</div>
                      <div style={{ fontSize: '0.9rem', color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.email || '-'}</div>
                    </div>
                  </div>
                  {companyProfile?.email && (
                    <button className="icon-btn" onClick={() => handleCopy(companyProfile.email, 'email')} style={{ width: '32px', height: '32px', border: 'none' }}>
                      {copiedField === 'email' ? <Check size={16} color="var(--color-success)" /> : <Copy size={16} />}
                    </button>
                  )}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderTop: '1px solid var(--color-surface-variant)', paddingTop: '0.75rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Globe size={18} color="var(--color-text-muted)" />
                    <div>
                      <div style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--color-text-muted)' }}>Web Sitesi</div>
                      <div style={{ fontSize: '0.9rem', color: 'var(--color-text-main)', fontWeight: 600 }}>{companyProfile?.website || '-'}</div>
                    </div>
                  </div>
                  {companyProfile?.website && (
                    <button className="icon-btn" onClick={() => handleCopy(companyProfile.website, 'web')} style={{ width: '32px', height: '32px', border: 'none' }}>
                      {copiedField === 'web' ? <Check size={16} color="var(--color-success)" /> : <Copy size={16} />}
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>

        </div>

        {/* SAĞ SÜTUN: Banka ve Kredi Kartı Listeleri */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Banka Hesapları */}
          <div className="summary-box" style={{ padding: '0', overflow: 'hidden' }}>
            <div 
              onClick={() => toggleSection('banks')} 
              style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', 
                padding: '1.25rem 1.5rem', cursor: 'pointer', background: 'var(--color-surface-hover)'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                <Building size={20} />
                <span>Banka Hesapları ({bankAccounts.length})</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <button
                  className="btn-inline-text"
                  onClick={(e) => { e.stopPropagation(); setAccountModal({ type: 'Banka', lockType: true }) }}
                >
                  <Plus size={14} /> Ekle
                </button>
                {expandedSections.banks ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
              </div>
            </div>

            {expandedSections.banks && (
              <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--color-border)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {bankAccounts.length === 0 ? (
                  <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Kayıtlı banka hesabı bulunamadı.</div>
                ) : (
                  bankAccounts.map((acc, idx) => (
                    <div key={acc.id || idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 0', borderBottom: idx < bankAccounts.length - 1 ? '1px solid var(--color-surface-variant)' : 'none' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <BankLogo bankName={acc.bank_logo_painter || acc.name} width={40} height={28} />
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--color-text-main)' }}>{acc.name}</div>
                          <div style={{ fontSize: '0.8rem', fontFamily: 'monospace', color: 'var(--color-text-muted)', marginTop: '0.2rem' }}>{acc.account_details || acc.iban || 'IBAN Belirtilmemiş'}</div>
                        </div>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <button className="icon-btn" onClick={() => setAccountModal({ account: acc })} style={{ width: '32px', height: '32px', border: 'none' }}>
                          <Pencil size={16} color="var(--color-accent)" />
                        </button>
                        {(acc.account_details || acc.iban) && (
                          <button className="icon-btn" onClick={() => handleCopy(acc.account_details || acc.iban, `bank-${idx}`)} style={{ width: '32px', height: '32px', border: 'none' }}>
                            {copiedField === `bank-${idx}` ? <Check size={16} color="var(--color-success)" /> : <Copy size={16} />}
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>

          {/* Kredi Kartları */}
          <div className="summary-box" style={{ padding: '0', overflow: 'hidden' }}>
            <div 
              onClick={() => toggleSection('cards')} 
              style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', 
                padding: '1.25rem 1.5rem', cursor: 'pointer', background: 'var(--color-surface-hover)'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', fontWeight: 800, color: 'var(--color-text-main)' }}>
                <CreditCard size={20} />
                <span>Kredi Kartları ({cardAccounts.length})</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <button
                  className="btn-inline-text"
                  onClick={(e) => { e.stopPropagation(); setAccountModal({ type: 'Kredi Kartı', lockType: true }) }}
                >
                  <Plus size={14} /> Ekle
                </button>
                {expandedSections.cards ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
              </div>
            </div>

            {expandedSections.cards && (
              <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--color-border)', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {cardAccounts.length === 0 ? (
                  <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>Kayıtlı kredi kartı bulunamadı.</div>
                ) : (
                  cardAccounts.map((acc, idx) => (
                    <div key={acc.id || idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 0', borderBottom: idx < cardAccounts.length - 1 ? '1px solid var(--color-surface-variant)' : 'none' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <BankLogo bankName={acc.bank_logo_painter || acc.name} width={40} height={28} />
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--color-text-main)' }}>{acc.name}</div>
                          <div style={{ fontSize: '0.8rem', fontFamily: 'monospace', color: 'var(--color-text-muted)', marginTop: '0.2rem' }}>{acc.account_details || 'Detay Belirtilmemiş'}</div>
                        </div>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <button className="icon-btn" onClick={() => setAccountModal({ account: acc })} style={{ width: '32px', height: '32px', border: 'none' }}>
                          <Pencil size={16} color="var(--color-accent)" />
                        </button>
                        {acc.account_details && (
                          <button className="icon-btn" onClick={() => handleCopy(acc.account_details, `card-${idx}`)} style={{ width: '32px', height: '32px', border: 'none' }}>
                            {copiedField === `card-${idx}` ? <Check size={16} color="var(--color-success)" /> : <Copy size={16} />}
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            )}
          </div>

        </div>

      </div>

      {accountModal && (
        <AccountFormModal
          account={accountModal.account}
          initialType={accountModal.type}
          lockType={accountModal.lockType}
          onClose={() => setAccountModal(null)}
          onSave={(body) => (accountModal.account ? updateAccount(accountModal.account.id, body) : addAccount(body))}
        />
      )}
    </div>
  )
}
