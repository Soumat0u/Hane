import { useState } from 'react'
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
  ArrowUpFromLine,
  Landmark,
  FileCheck2,
} from 'lucide-react'
import appIcon from '../assets/icon.png'
import NewTransactionFormModal from './NewTransactionFormModal'

const NEW_TRANSACTION_TYPES = [
  { name: 'Ödeme', icon: ArrowUpFromLine },
  { name: 'Transfer', icon: ArrowRightLeft },
  { name: 'Borçlanma', icon: Landmark },
  { name: 'Kredi Kullanımı', icon: Wallet },
  { name: 'Satış', icon: FileCheck2 },
]

export default function Sidebar() {
  const navigate = useNavigate()
  const [activeTxType, setActiveTxType] = useState(null)

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
            {/* Insert Yeni İşlem section after Finans */}
            {group.label === 'Sistem' && (
              <div>
                <div className="nav-section-label">Yeni İşlem</div>
                {NEW_TRANSACTION_TYPES.map((item) => (
                  <button
                    key={item.name}
                    type="button"
                    className="nav-item"
                    onClick={() => setActiveTxType(item.name)}
                  >
                    <item.icon size={20} className="nav-icon" />
                    <span>{item.name}</span>
                  </button>
                ))}
              </div>
            )}
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




      {activeTxType && (
        <NewTransactionFormModal
          type={activeTxType}
          onClose={() => setActiveTxType(null)}
        />
      )}
    </aside>
  )
}
