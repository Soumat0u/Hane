import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  FolderKanban,
  Wallet,
  Receipt,
  ArrowDownToLine,
  Shield,
  ArrowRightLeft,
  Settings,
  LogOut,
  User,
} from 'lucide-react'
import appIcon from '../assets/icon.png'

export default function Sidebar() {
  const navigate = useNavigate()

  const navGroups = [
    {
      label: 'Genel',
      items: [
        { name: 'Genel Bakış', path: '/dashboard', icon: LayoutDashboard },
        { name: 'Projeler', path: '/dashboard/projects', icon: FolderKanban },
        { name: 'Profil', path: '/dashboard/profile', icon: User },
      ],
    },
    {
      label: 'Finans',
      items: [
        { name: 'Kasa', path: '/dashboard/accounts', icon: Wallet },
        { name: 'Borçlar', path: '/dashboard/debts', icon: Receipt },
        { name: 'Alacaklar', path: '/dashboard/receivables', icon: ArrowDownToLine },
        { name: 'Finansman Gücü', path: '/dashboard/finance-power', icon: Shield },
        { name: 'Hareketler', path: '/dashboard/transactions', icon: ArrowRightLeft },
      ],
    },
    {
      label: 'Sistem',
      items: [
        { name: 'Ayarlar', path: '/dashboard/settings', icon: Settings },
      ],
    },
  ]

  const handleLogout = () => {
    localStorage.removeItem('auth_token')
    navigate('/login')
  }

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div style={{ width: '46px', height: '46px', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <img src={appIcon} alt="Hane" style={{ width: '38px', height: '38px', borderRadius: '10px', objectFit: 'contain' }} />
        </div>
        <div className="brand-text">
          <h2>Hane</h2>
          <span className="badge">Yönetim Paneli</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navGroups.map((group) => (
          <div key={group.label}>
            <div className="nav-section-label">{group.label}</div>
            {group.items.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                end={item.path === '/dashboard'}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
                title={item.name}
              >
                <item.icon size={20} className="nav-icon" />
                <span>{item.name}</span>
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      <div className="sidebar-footer">
        <button onClick={handleLogout} className="logout-btn" title="Çıkış Yap">
          <LogOut size={20} className="nav-icon" />
          <span>Çıkış Yap</span>
        </button>
      </div>
    </aside>
  )
}
