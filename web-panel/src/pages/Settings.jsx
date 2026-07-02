import { Smartphone, LogOut, ArrowRight, FolderTree } from 'lucide-react'
import { useNavigate } from 'react-router-dom' // Yönlendirme için eklendi

export default function Settings() {
  const navigate = useNavigate()

  // Çıkış yapma fonksiyonu
  const handleLogout = () => {
    // 1. Tarayıcıda tutulan oturum verilerini temizle 
    // (Projene göre 'token', 'user' veya 'access_token' gibi isimleri kendi yapına göre düzenleyebilirsin)
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    sessionStorage.clear()

    // Eğer src/context/DataContext.jsx içinde bir state sıfırlama fonksiyonun varsa
    // onu da burada çağırabilirsin. Örn: clearUserData()

    // 2. Kullanıcıyı Login sayfasına yönlendir
    navigate('/login')
  }

  return (
    <div>
      <div className="page-header-banner bg-settings">
        <div>
          <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)' }}>AYARLAR</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem' }}>Hesap & Tercihler</div>
        </div>
      </div>

      <div className="dashboard-content-grid" style={{ gridTemplateColumns: '1fr', gap: '2rem' }}>

        {/* UYGULAMA VE VERİ */}
        <div>
          <div className="section-header">
            <span className="section-title">UYGULAMA VE VERİ</span>
          </div>
          <div className="list-group">
            <div className="list-item" onClick={() => navigate('/dashboard/settings/categories')} style={{ cursor: 'pointer' }}>
              <div className="list-icon-box">
                <FolderTree size={20} className="text-info" />
              </div>
              <div className="list-item-content">
                <div className="list-item-title">Kategori Yönetimi</div>
                <div className="list-item-subtitle">Ana ve alt kategorileri düzenle</div>
              </div>
              <ArrowRight size={14} className="text-muted" />
            </div>
            <div className="list-item">
              <div className="list-icon-box">
                <Smartphone size={20} className="text-success" />
              </div>
              <div className="list-item-content">
                <div className="list-item-title">Hakkında</div>
                <div className="list-item-subtitle">Sürüm: 1.0.0 (Web)</div>
              </div>
            </div>
          </div>
        </div>

        {/* ÇIKIŞ YAP */}
        <div style={{ justifySelf: 'center', width: '100%', maxWidth: '280px', marginTop: '1rem' }}>
          <button
            onClick={handleLogout} // Fonksiyonu butona bağladık
            className="list-item"
            style={{ width: '100%', background: 'var(--color-surface)', borderRadius: 'var(--radius-xl)', border: '1px solid var(--color-border)', justifyContent: 'center', color: 'var(--color-danger)' }}
          >
            <LogOut size={18} style={{ marginRight: '0.5rem' }} />
            <span style={{ fontWeight: '600' }}>Güvenli Çıkış Yap</span>
          </button>
        </div>

      </div>
    </div>
  )
}