import { useState, useEffect, useRef } from 'react'
import { Navigate, Outlet, useNavigate } from 'react-router-dom'
import { Sun, Moon, Bell, AlertTriangle, ArrowDownToLine, CreditCard, Repeat, Check, CheckCheck, Settings, User } from 'lucide-react'
import Sidebar from '../components/Sidebar'
import { DataProvider, useData } from '../context/DataContext'
import RecurringFormModal, { DeleteRecurringModal } from '../components/RecurringFormModal'

// Vadesi henüz gelmemiş ama bu kadar gün içinde olan tekrarlayan işlem şablonları
// bildirim çanında "yaklaşan" olarak önizlenir (vadesi gelenler sunucuda otomatik onaylanır).
const UPCOMING_RECURRING_WINDOW_DAYS = 3

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
    accounts,
    updateRecurringTransaction,
    deleteRecurringTransaction,
    companyProfile,
  } = useData()

  const navigate = useNavigate()
  const [showNotifications, setShowNotifications] = useState(false)
  const [confirmingId, setConfirmingId] = useState(null)
  const [editTarget, setEditTarget] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const dropdownRef = useRef(null)

  const today = new Date(); today.setHours(0, 0, 0, 0)
  const dueTemplates = recurringTransactions.filter((r) => {
    if (!r.is_active || !r.next_due_date) return false
    const due = new Date(r.next_due_date)
    return !Number.isNaN(due.getTime()) && due <= today
  })
  const upcomingTemplates = recurringTransactions.filter((r) => {
    if (!r.is_active || !r.next_due_date) return false
    const due = new Date(r.next_due_date)
    if (Number.isNaN(due.getTime())) return false
    const limit = new Date(today)
    limit.setDate(limit.getDate() + UPCOMING_RECURRING_WINDOW_DAYS)
    return due > today && due <= limit
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
              <span className="notification-title">
                Bildirimler
                {unreadNotificationsCount > 0 && (
                  <span className="notification-header-badge">{unreadNotificationsCount} yeni</span>
                )}
              </span>
              {unreadNotificationsCount > 0 && (
                <button className="notification-clear-btn" onClick={markAllNotificationsRead}>
                  Tümünü Oku
                </button>
              )}
            </div>
            
            <div className="notification-dropdown-body">
              {dueTemplates.length === 0 && upcomingTemplates.length === 0 && notifications.length === 0 ? (
                <div className="notification-empty">
                  <div className="notification-empty-icon">
                    <Bell size={32} />
                  </div>
                  <span className="notification-empty-title">Her Şey Güncel!</span>
                  <span className="notification-empty-subtitle">Okunmamış veya yaklaşan bir bildiriminiz bulunmuyor.</span>
                </div>
              ) : (
                <>
                  {dueTemplates.length > 0 && (
                    <div className="notification-section">
                      <div className="notification-section-title">
                        <span>Tekrarlayan İşlemler</span>
                        <span className="notification-section-badge">{dueTemplates.length}</span>
                      </div>
                      {dueTemplates.map((r) => (
                        <div key={r.id} className="notification-item" onClick={() => setEditTarget(r)} style={{ cursor: 'pointer' }}>
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
                            className="notification-action-btn"
                            disabled={confirmingId === r.id}
                            onClick={(e) => { e.stopPropagation(); handleConfirm(r.id) }}
                          >
                            <Check size={14} /> Onayla
                          </button>
                        </div>
                      ))}
                    </div>
                  )}

                  {upcomingTemplates.length > 0 && (
                    <div className="notification-section">
                      <div className="notification-section-title">
                        <span>Yaklaşan Tekrarlayan İşlemler</span>
                        <span className="notification-section-badge">{upcomingTemplates.length}</span>
                      </div>
                      {upcomingTemplates.map((r) => (
                        <div
                          key={r.id}
                          className="notification-item"
                          onClick={() => setEditTarget(r)}
                          style={{ cursor: 'pointer' }}
                        >
                          <div className="notification-item-icon-box">
                            <Repeat size={18} />
                          </div>
                          <div className="notification-item-content">
                            <div className="notification-item-header">
                              <span className="notification-item-type">Yaklaşan Tekrarlayan İşlem</span>
                              <span className="notification-item-date">{r.next_due_date}</span>
                            </div>
                            <span className="notification-item-desc">
                              {(r.description || r.category || 'İşlem')} — {formatCurrency(r.amount)}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {notifications.length > 0 && (
                    <div className="notification-section">
                      <div className="notification-section-title">
                        <span>Yaklaşan ve Geciken İşlemler</span>
                      </div>
                      {notifications.map((n) => {
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
                            <div className="notification-item-status" onClick={(e) => e.stopPropagation()}>
                              {read ? (
                                <span className="read-status read" title="Okundu">
                                  <CheckCheck size={16} />
                                </span>
                              ) : (
                                <button 
                                  className="read-status-btn" 
                                  onClick={() => markNotificationRead(n)}
                                  title="Okundu Olarak İşaretle"
                                >
                                  <CheckCheck size={16} />
                                </button>
                              )}
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  )}
                </>
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
        <div className="avatar" style={{ overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {companyProfile?.logo ? (
            <img 
              src={companyProfile.logo.startsWith('/media/') 
                ? (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' ? 'http://localhost:8000' : 'https://web-production-77031.up.railway.app') + companyProfile.logo
                : companyProfile.logo
              } 
              alt="Logo" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
            />
          ) : (
            <User size={20} />
          )}
        </div>
      </button>

      {editTarget && (
        <RecurringFormModal
          existing={editTarget}
          accounts={accounts}
          onClose={() => setEditTarget(null)}
          onSave={(body) => updateRecurringTransaction(editTarget.id, body)}
          onDelete={(r) => { setDeleteTarget({ id: r.id, description: r.description || r.category }); setEditTarget(null) }}
        />
      )}
      {deleteTarget && (
        <DeleteRecurringModal
          target={deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={async (id) => { await deleteRecurringTransaction(id); setDeleteTarget(null) }}
        />
      )}
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
