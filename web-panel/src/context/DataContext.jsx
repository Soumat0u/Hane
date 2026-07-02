import { createContext, useContext, useState, useEffect, useCallback, useMemo } from 'react'
import { api } from '../api'

/**
 * Uygulama verisini (projeler + işlemler) BİR KEZ yükleyip tüm sayfalarda paylaşan store.
 * Mobil taraftaki `FinanceProvider` ile aynı mantık: veriler bellekte tutulur, sayfa
 * geçişlerinde yeniden çekilmez — böylece navigasyon anında ve akıcı olur.
 *
 * Sağlayıcı `DashboardLayout` içinde monte edilir; iç rotalar (`Outlet`) değişse de
 * sağlayıcı monte kaldığı için state korunur.
 */
const DataContext = createContext(null)

export function DataProvider({ children }) {
  const [projects, setProjects] = useState([])
  const [transactions, setTransactions] = useState([])
  const [cheques, setCheques] = useState([])
  const [receivables, setReceivables] = useState([])
  const [accounts, setAccounts] = useState([])
  const [budgetLines, setBudgetLines] = useState([])
  const [loans, setLoans] = useState([])
  const [contacts, setContacts] = useState([])
  const [categories, setCategories] = useState([])
  const [recurringTransactions, setRecurringTransactions] = useState([])
  const [companyProfile, setCompanyProfile] = useState(null)
  const [loading, setLoading] = useState(true)
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState('')

  const [readKeys, setReadKeys] = useState(() => {
    try {
      const saved = localStorage.getItem('read_notifications')
      return saved ? JSON.parse(saved) : []
    } catch {
      return []
    }
  })

  useEffect(() => {
    localStorage.setItem('read_notifications', JSON.stringify(readKeys))
  }, [readKeys])

  const load = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const results = await Promise.allSettled([
        api.get('/projects/'),
        api.get('/transactions/'),
        api.get('/cheques/'),
        api.get('/receivables/'),
        api.get('/accounts/'),
        api.get('/company-profile/'),
        api.get('/loans/'),
        api.get('/contacts/'),
        api.get('/categories/'),
        api.get('/budget-lines/'),
        api.get('/recurring-transactions/'),
      ])

      const projs = results[0].status === 'fulfilled' ? results[0].value : []
      const txns = results[1].status === 'fulfilled' ? results[1].value : []
      const chqs = results[2].status === 'fulfilled' ? results[2].value : []
      const recs = results[3].status === 'fulfilled' ? results[3].value : []
      const accs = results[4].status === 'fulfilled' ? results[4].value : []
      const profile = results[5].status === 'fulfilled' ? results[5].value : null
      const lns = results[6].status === 'fulfilled' ? results[6].value : []
      const cnts = results[7].status === 'fulfilled' ? results[7].value : []
      const cats = results[8].status === 'fulfilled' ? results[8].value : []
      const bls = results[9].status === 'fulfilled' ? results[9].value : []
      const rects = results[10].status === 'fulfilled' ? results[10].value : []

      setProjects(Array.isArray(projs) ? projs : [])
      setTransactions(Array.isArray(txns) ? txns : [])
      setCheques(Array.isArray(chqs) ? chqs : [])
      setReceivables(Array.isArray(recs) ? recs : [])
      setAccounts(Array.isArray(accs) ? accs : [])
      setLoans(Array.isArray(lns) ? lns : [])
      setContacts(Array.isArray(cnts) ? cnts : [])
      setCategories(Array.isArray(cats) ? cats : [])
      setBudgetLines(Array.isArray(bls) ? bls : [])
      setRecurringTransactions(Array.isArray(rects) ? rects : [])
      setCompanyProfile(profile)
      setLoaded(true)
    } catch {
      setError('Veriler yüklenemedi. Lütfen tekrar deneyin.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const updateCompanyProfile = useCallback(async (updatedData) => {
    try {
      const updated = await api.put('/company-profile/', updatedData)
      setCompanyProfile(updated)
      return updated
    } catch (e) {
      console.error('Failed to update company profile', e)
      throw e
    }
  }, [])

  /**
   * Mobil "Borçlanma" akışının web karşılığı: kişiyi (tedarikçi) bul ya da oluştur,
   * ardından backend'in borç bakiyesini yükseltmesi için `type: 'Gider'`,
   * `category: 'Borçlanma'` bir işlem kaydı oluştur. Sonra veriyi tazele.
   */
  const addDebt = useCallback(
    async ({ amount, contactName, dueDate = '', projectId = null, description = '' }) => {
      const name = (contactName || '').trim()

      let contact = contacts.find(
        (c) => (c.name || '').toLowerCase() === name.toLowerCase() && name.length > 0,
      )
      if (!contact) {
        contact = await api.post('/contacts/', {
          name: name || 'Yeni Tedarikçi/Taşeron',
          kind: 'supplier',
        })
      }

      const today = new Date().toISOString().split('T')[0]
      await api.post('/transactions/', {
        project_id: projectId,
        type: 'Gider',
        amount,
        date: today,
        due_date: dueDate,
        category: 'Borçlanma',
        contact: contact?.id ?? null,
        source_name: name,
        description,
      })

      await load()
    },
    [contacts, load],
  )

  /** Bir işlemi günceller (PUT) ve veriyi tazeler. */
  const updateTransaction = useCallback(
    async (id, body) => {
      const updated = await api.put(`/transactions/${id}/`, body)
      await load()
      return updated
    },
    [load],
  )

  /** Yeni bir işlem oluşturur (POST) ve veriyi tazeler. */
  const addTransaction = useCallback(
    async (body) => {
      const created = await api.post('/transactions/', body)
      await load()
      return created
    },
    [load],
  )

  /** Yeni bir kredi (Loan) kaydı oluşturur ve veriyi tazeler. */
  const addLoan = useCallback(
    async (body) => {
      const created = await api.post('/loans/', body)
      await load()
      return created
    },
    [load],
  )

  const updateLoan = useCallback(async (id, body) => {
    const updated = await api.put(`/loans/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteLoan = useCallback(async (id) => {
    await api.delete(`/loans/${id}/`)
    await load()
  }, [load])

  /** Yeni bir proje oluşturur (POST) ve veriyi tazeler. */
  const addProject = useCallback(
    async (body) => {
      const created = await api.post('/projects/', body)
      await load()
      return created
    },
    [load],
  )

  /** Bir projeyi günceller (PUT) ve veriyi tazeler. */
  const updateProject = useCallback(
    async (id, body) => {
      const updated = await api.put(`/projects/${id}/`, body)
      await load()
      return updated
    },
    [load],
  )

  /** Bir projeyi siler (DELETE) ve veriyi tazeler. */
  const deleteProject = useCallback(
    async (id) => {
      await api.delete(`/projects/${id}/`)
      await load()
    },
    [load],
  )

  // --- Hesaplar (Kasa) ---
  const addAccount = useCallback(async (body) => {
    const created = await api.post('/accounts/', body)
    await load()
    return created
  }, [load])

  const updateAccount = useCallback(async (id, body) => {
    const updated = await api.put(`/accounts/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteAccount = useCallback(async (id) => {
    await api.delete(`/accounts/${id}/`)
    await load()
  }, [load])

  // --- Cariler (Contacts) ---
  const addContact = useCallback(async (body) => {
    const created = await api.post('/contacts/', body)
    await load()
    return created
  }, [load])

  const updateContact = useCallback(async (id, body) => {
    const updated = await api.put(`/contacts/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteContact = useCallback(async (id) => {
    await api.delete(`/contacts/${id}/`)
    await load()
  }, [load])

  // --- Çekler (Cheques) ---
  const addCheque = useCallback(async (body) => {
    const created = await api.post('/cheques/', body)
    await load()
    return created
  }, [load])

  const updateCheque = useCallback(async (id, body) => {
    const updated = await api.put(`/cheques/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteCheque = useCallback(async (id) => {
    await api.delete(`/cheques/${id}/`)
    await load()
  }, [load])

  // --- Satışlar (Sales) ---
  const addSale = useCallback(async (body) => {
    const created = await api.post('/sales/', body)
    await load()
    return created
  }, [load])

  // --- Alacaklar (Receivables) ---
  const addReceivable = useCallback(async (body) => {
    const created = await api.post('/receivables/', body)
    await load()
    return created
  }, [load])

  const updateReceivable = useCallback(async (id, body) => {
    const updated = await api.put(`/receivables/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteReceivable = useCallback(async (id) => {
    await api.delete(`/receivables/${id}/`)
    await load()
  }, [load])

  /**
   * Bir alacaktan tahsilat yapar: Receivable.collected_amount güncellenir ve
   * seçilen hesaba 'Tahsilat' tipi bir işlem düşülür (mobildeki
   * `FinanceProvider.collectReceivable` ile aynı mantık). `to_account` FK
   * alanı kullanılır (dest_name değil) — böylece bakiye, backend'in
   * sinyal tabanlı yeniden hesaplama yolundan güncellenir.
   */
  const collectReceivable = useCallback(
    async ({ receivable, amount, toAccountId, date = '' }) => {
      const newCollected = (parseFloat(receivable.collected_amount) || 0) + amount
      const fullyCollected = newCollected >= (parseFloat(receivable.total_amount) || 0)
      await api.put(`/receivables/${receivable.id}/`, {
        ...receivable,
        collected_amount: newCollected,
        status: fullyCollected ? 'collected' : 'partial',
      })
      await api.post('/transactions/', {
        type: 'Tahsilat',
        category: 'Tahsilat',
        amount,
        date: date || new Date().toISOString().split('T')[0],
        project_id: receivable.project ?? null,
        description: receivable.description || '',
        to_account: toAccountId ?? null,
      })
      await load()
    },
    [load],
  )

  // --- Tekrarlayan İşlemler (Recurring Transactions) ---
  const addRecurringTransaction = useCallback(async (body) => {
    const created = await api.post('/recurring-transactions/', body)
    await load()
    return created
  }, [load])

  const updateRecurringTransaction = useCallback(async (id, body) => {
    const updated = await api.put(`/recurring-transactions/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteRecurringTransaction = useCallback(async (id) => {
    await api.delete(`/recurring-transactions/${id}/`)
    await load()
  }, [load])

  const confirmRecurringTransaction = useCallback(async (id) => {
    await api.post(`/recurring-transactions/${id}/confirm/`, {})
    await load()
  }, [load])

  const addBudgetLine = useCallback(async (body) => {
    const created = await api.post('/budget-lines/', body)
    await load()
    return created
  }, [load])

  const updateBudgetLine = useCallback(async (id, body) => {
    const updated = await api.put(`/budget-lines/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteBudgetLine = useCallback(async (id) => {
    await api.delete(`/budget-lines/${id}/`)
    await load()
  }, [load])

  const addCategory = useCallback(async (body) => {
    const created = await api.post('/categories/', body)
    await load()
    return created
  }, [load])

  const updateCategory = useCallback(async (id, body) => {
    const updated = await api.put(`/categories/${id}/`, body)
    await load()
    return updated
  }, [load])

  const deleteCategory = useCallback(async (id) => {
    await api.delete(`/categories/${id}/`)
    await load()
  }, [load])

  /** Bir işlemi siler (DELETE) ve veriyi tazeler. */
  const deleteTransaction = useCallback(
    async (id) => {
      await api.delete(`/transactions/${id}/`)
      await load()
    },
    [load],
  )

  const getReceivableKindLabel = useCallback((kind) => {
    switch (kind) {
      case 'installment': return 'Satış taksiti';
      case 'customer': return 'Müşteri alacağı';
      case 'government': return 'Devlet alacağı';
      case 'retention': return 'Hakediş';
      default: return 'Alacak';
    }
  }, [])

  const notifications = useMemo(() => {
    const list = []
    
    // Verilen ve Alınan Çekler (cashed olmayanlar)
    cheques.forEach(c => {
      if (c.status !== 'cashed') {
        const isPayable = c.direction === 'issued'
        list.push({
          id: `cheque-${c.id}`,
          title: c.bank_name ? `${c.bank_name} çeki` : (isPayable ? 'Verilen çek' : 'Alınan çek'),
          amount: parseFloat(c.amount || 0),
          rawDate: c.due_date,
          isPayable,
        })
      }
    })

    // Gider İşlemleri (due_date'i olanlar)
    transactions.forEach(t => {
      if (t.due_date && t.type === 'Gider') {
        list.push({
          id: `tx-${t.id}`,
          title: t.description || t.category || 'Ödeme',
          amount: parseFloat(t.amount || 0),
          rawDate: t.due_date,
          isPayable: true,
        })
      }
    })

    // Alacaklar (remaining > 0 olanlar)
    receivables.forEach(r => {
      const remaining = parseFloat(r.remaining || 0)
      if (remaining > 0) {
        list.push({
          id: `rec-${r.id}`,
          title: r.description || getReceivableKindLabel(r.kind),
          amount: remaining,
          rawDate: r.due_date,
          isPayable: false,
        })
      }
    })

    // Tarihe göre sıralama (tarihi olmayanlar en sona)
    list.sort((a, b) => {
      if (!a.rawDate && !b.rawDate) return 0
      if (!a.rawDate) return 1
      if (!b.rawDate) return -1
      return new Date(a.rawDate) - new Date(b.rawDate)
    })

    return list
  }, [cheques, transactions, receivables, getReceivableKindLabel])

  const getNotificationKey = useCallback((p) => {
    return `${p.isPayable}|${p.title}|${p.rawDate}|${p.amount}`
  }, [])

  const markNotificationRead = useCallback((p) => {
    const key = getNotificationKey(p)
    setReadKeys(prev => {
      if (prev.includes(key)) return prev
      return [...prev, key]
    })
  }, [getNotificationKey])

  const markAllNotificationsRead = useCallback(() => {
    const keysToAdd = notifications.map(p => getNotificationKey(p))
    setReadKeys(prev => {
      const newKeys = new Set([...prev, ...keysToAdd])
      return Array.from(newKeys)
    })
  }, [notifications, getNotificationKey])

  const unreadNotificationsCount = useMemo(() => {
    return notifications.filter(p => !readKeys.includes(getNotificationKey(p))).length
  }, [notifications, readKeys, getNotificationKey])

  const value = useMemo(
    () => ({
      projects,
      transactions,
      cheques,
      receivables,
      accounts,
      loans,
      contacts,
      categories,
      budgetLines,
      recurringTransactions,
      companyProfile,
      updateCompanyProfile,
      addProject,
      updateProject,
      deleteProject,
      addCategory,
      updateCategory,
      deleteCategory,
      addBudgetLine,
      updateBudgetLine,
      deleteBudgetLine,
      addDebt,
      addTransaction,
      addLoan,
      updateLoan,
      deleteLoan,
      addAccount,
      updateAccount,
      deleteAccount,
      addContact,
      updateContact,
      deleteContact,
      addCheque,
      updateCheque,
      deleteCheque,
      addSale,
      addReceivable,
      updateReceivable,
      deleteReceivable,
      collectReceivable,
      addRecurringTransaction,
      updateRecurringTransaction,
      deleteRecurringTransaction,
      confirmRecurringTransaction,
      updateTransaction,
      deleteTransaction,
      notifications,
      readKeys,
      unreadNotificationsCount,
      getNotificationKey,
      markNotificationRead,
      markAllNotificationsRead,
      loading,
      loaded,
      error,
      refresh: load,
    }),
    [
      projects,
      transactions,
      cheques,
      receivables,
      accounts,
      loans,
      contacts,
      categories,
      budgetLines,
      recurringTransactions,
      companyProfile,
      updateCompanyProfile,
      addProject,
      updateProject,
      deleteProject,
      addCategory,
      updateCategory,
      deleteCategory,
      addBudgetLine,
      updateBudgetLine,
      deleteBudgetLine,
      addDebt,
      addTransaction,
      addLoan,
      updateLoan,
      deleteLoan,
      addAccount,
      updateAccount,
      deleteAccount,
      addContact,
      updateContact,
      deleteContact,
      addCheque,
      updateCheque,
      deleteCheque,
      addSale,
      addReceivable,
      updateReceivable,
      deleteReceivable,
      collectReceivable,
      addRecurringTransaction,
      updateRecurringTransaction,
      deleteRecurringTransaction,
      confirmRecurringTransaction,
      updateTransaction,
      deleteTransaction,
      notifications,
      readKeys,
      unreadNotificationsCount,
      getNotificationKey,
      markNotificationRead,
      markAllNotificationsRead,
      loading,
      loaded,
      error,
      load,
    ],
  )

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useData() {
  const ctx = useContext(DataContext)
  if (!ctx) throw new Error('useData bir DataProvider içinde kullanılmalıdır')
  return ctx
}
