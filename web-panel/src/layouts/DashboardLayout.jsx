import { useState, useEffect, useRef } from 'react'
import { Navigate, Outlet, useNavigate } from 'react-router-dom'
import { Sun, Moon, Bell, AlertTriangle, ArrowDownToLine, CreditCard, Info, Repeat, Check, Settings, User } from 'lucide-react'
import Sidebar from '../components/Sidebar'
import { DataProvider, useData } from '../context/DataContext'

function TopbarActions({ theme, toggleTheme }) {
  const {
    notifications,
    readKeys,
    unreadNotificationsCount,
    getNotificationKey,
    markNotificationRead,
    markAllNotificationsRead,
    recurringTransactions,
    confirmRecurringTransaction,
  } = useData()

  const navigate = useNavigate()
  const [showNotifications, setShowNotifications] = useState(false)
  const [confirmingId, setConfirmingId] = useState(null)
  const dropdownRef = useRef(null)

  const today = new Date(); today.setHours(0, 0, 0, 0)
  const dueTemplates = recurringTransactions.filter((r) => {
    if (!r.is_active || !r.next_due_date) return false
    const due = new Date(r.next_due_date)
    return !Number.isNaN(due.getTime()) && due <= today
  })

  const handleConfirm = async (id) => {
    setConfirmingId(id)
    try {
      await confirmRecurringTransaction(id)
    } catch {
      alert('Tekrarlayan işlem onaylanamadı.')
    } finally {
      setConfirmingId(null)
    }
  }

  const toggleNotifications = () => setShowNotifications(s => !s)

  useEffect(() => {
    function handleClickOutside(event) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowNotifications(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const formatCurrency = (val) => {
    return new Intl.NumberFormat('tr-TR', { style: 'currency', currency: 'TRY' }).format(val)
  }

  const isOverdue = (dateStr) => {
    if (!dateStr) return false
    const date = new Date(dateStr)
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    return date < yesterday
  }

  return (
    <div className="topbar-actions">
      <button className="theme-toggle-btn" onClick={() => navigate('/dashboard/settings')} title="Ayarlar">
        <Settings size={20} />
      </button>

      <button className="theme-toggle-btn" onClick={toggleTheme} title="Tema Değiştir">
        {theme === 'light' ? <Moon size={20} /> : <Sun size={20} />}
      </button>

      <div className="notification-container" ref={dropdownRef}>
        <button className="notification-btn" onClick={toggleNotifications} title="Bildirimler">
          <Bell size={20} />
          {unreadNotificationsCount > 0 && <span className="notification-badge" />}
        </button>
        
        {showNotifications && (
          <div className="notification-dropdown">
            <div className="notification-header">
              <span className="notification-title">Bildirimler</span>
              {unreadNotificationsCount > 0 && (
                <button className="notification-clear-btn" onClick={markAllNotificationsRead}>
                  Tümünü Oku
                </button>
              )}
            </div>
            {dueTemplates.length > 0 && (
              <div className="notification-list" style={{ borderBottom: '1px solid var(--color-border)' }}>
                {dueTemplates.map((r) => (
                  <div key={r.id} className="notification-item">
                    <div className="notification-item-icon-box warning">
                      <Repeat size={18} />
                    </div>
                    <div className="notification-item-content">
                      <div className="notification-item-header">
                        <span className="notification-item-type">Tekrarlayan İşlem</span>
                        <span className="notification-item-date overdue">{r.next_due_date}</span>
                      </div>
                      <span className="notification-item-desc">
                        {(r.description || r.category || 'İşlem')} — {formatCurrency(r.amount)}
                      </span>
                    </div>
                    <button
                      className="btn-inline-text"
                      style={{ flexShrink: 0 }}
                      disabled={confirmingId === r.id}
                      onClick={(e) => { e.stopPropagation(); handleConfirm(r.id) }}
                    >
                      <Check size={14} /> Onayla
                    </button>
                  </div>
                ))}
              </div>
            )}
            <div className="notification-list">
              {notifications.length === 0 ? (
                <div className="notification-empty">
                  <Info size={32} />
                  <span>Bildiriminiz bulunmuyor.</span>
                </div>
              ) : (
                notifications.map((n) => {
                  const overdue = isOverdue(n.rawDate)
                  const read = readKeys.includes(getNotificationKey(n))
                  
                  let Icon = n.isPayable ? CreditCard : ArrowDownToLine
                  let colorClass = n.isPayable ? 'danger' : 'success'
                  if (overdue) {
                    Icon = AlertTriangle
                    colorClass = 'warning'
                  }

                  return (
                    <div 
                      key={n.id} 
                      className={`notification-item ${read ? 'read' : ''}`}
                      onClick={() => markNotificationRead(n)}
                    >
                      {!read && <div className="notification-item-unread-dot" />}
                      <div className={`notification-item-icon-box ${colorClass}`}>
                        <Icon size={18} />
                      </div>
                      <div className="notification-item-content">
                        <div className="notification-item-header">
                          <span className="notification-item-type">
                            {overdue ? (n.isPayable ? 'Gecikmiş Ödeme' : 'Gecikmiş Tahsilat') : (n.isPayable ? 'Yaklaşan Ödeme' : 'Yaklaşan Tahsilat')}
                          </span>
                          <span className={`notification-item-date ${overdue ? 'overdue' : ''}`}>
                            {n.rawDate ? new Date(n.rawDate).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' }) : ''}
                          </span>
                        </div>
                        <span className="notification-item-desc">
                          {n.title} için {formatCurrency(n.amount)} tutarında işlem bekleniyor.
                        </span>
                      </div>
                    </div>
                  )
                })
              )}
            </div>
          </div>
        )}
      </div>

      <button
        className="user-profile"
        onClick={() => navigate('/dashboard/profile')}
        style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
        title="Profil"
      >
        <div className="avatar">
          <User size={20} />
        </div>
      </button>
    </div>
  )
}

export default function DashboardLayout() {
  const token = localStorage.getItem('auth_token')
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'light')

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('theme', theme)
  }, [theme])

  const toggleTheme = () => {
    setTheme(t => t === 'light' ? 'dark' : 'light')
  }

  if (!token) {
    return <Navigate to="/login" replace />
  }

  return (
    <DataProvider>
      <div className="dashboard-layout">
        <Sidebar />
        <div className="main-content">
          <header className="topbar">
            <div className="topbar-search">
              <input type="text" placeholder="Arama yap..." className="search-input" />
            </div>
            <TopbarActions theme={theme} toggleTheme={toggleTheme} />
          </header>
          <main className="content-area">
            <Outlet />
          </main>
        </div>
      </div>
    </DataProvider>
  )
}
