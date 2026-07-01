import { User, Bell, Lock, Smartphone, LogOut, ArrowRight, FolderTree } from 'lucide-react'

export default function Settings() {
  return (
    <div>
      <div className="page-header-banner bg-settings">
        <div>
          <div className="total-card-label" style={{ color: 'rgba(255,255,255,0.7)' }}>AYARLAR</div>
          <div className="total-card-value" style={{ fontSize: '1.5rem' }}>Hesap & Tercihler</div>
        </div>
      </div>

      <div className="dashboard-content-grid" style={{ gridTemplateColumns: '1fr', gap: '2rem' }}>
        
        {/* PROFİL BİLGİLERİ */}
        <div>
          <div className="section-header">
            <span className="section-title">HESAP</span>
          </div>
          <div className="list-group">
            <div className="list-item">
              <div className="list-icon-box">
                <User size={20} className="text-primary" />
              </div>
              <div className="list-item-content">
                <div className="list-item-title">Profil Bilgileri</div>
                <div className="list-item-subtitle">Ad, soyad ve e-posta güncellemeleri</div>
              </div>
              <ArrowRight size={14} className="text-muted" />
            </div>
            <div className="list-item">
              <div className="list-icon-box">
                <Lock size={20} className="text-warning" />
              </div>
              <div className="list-item-content">
                <div className="list-item-title">Şifre & Güvenlik</div>
                <div className="list-item-subtitle">Şifre değiştirme ve 2FA</div>
              </div>
              <ArrowRight size={14} className="text-muted" />
            </div>
          </div>
        </div>

        {/* UYGULAMA TERCİHLERİ */}
        <div>
          <div className="section-header">
            <span className="section-title">UYGULAMA VE VERİ</span>
          </div>
          <div className="list-group">
            <div className="list-item" onClick={() => window.location.href = '/dashboard/settings/categories'} style={{ cursor: 'pointer' }}>
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
                <Bell size={20} className="text-primary" />
              </div>
              <div className="list-item-content">
                <div className="list-item-title">Bildirimler</div>
                <div className="list-item-subtitle">E-posta ve push bildirim ayarları</div>
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
        <div>
          <button className="list-item" style={{ width: '100%', background: 'var(--color-surface)', borderRadius: 'var(--radius-xl)', border: '1px solid var(--color-border)', justifyContent: 'center', color: 'var(--color-danger)' }}>
            <LogOut size={18} style={{ marginRight: '0.5rem' }} />
            <span style={{ fontWeight: '600' }}>Güvenli Çıkış Yap</span>
          </button>
        </div>

      </div>
    </div>
  )
}
