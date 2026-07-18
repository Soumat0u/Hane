import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Eye, EyeOff } from 'lucide-react'
import { api } from '../api'

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleLogin = async (e) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')

    try {
      const data = await api.post('/auth/login/', { email, password })
      localStorage.setItem('auth_token', data.token)
      navigate('/dashboard')
    } catch (err) {
      setError(err.detail || err.non_field_errors?.[0] || 'Giriş bilgileri hatalı.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="app-container" style={{ background: 'var(--color-bg)' }}>
      <main className="center-content">
        <div className="glass-card">
          <h1 className="title">Hane</h1>
          <p className="subtitle">Yönetim Paneline Hoş Geldiniz</p>

          {error && <div className="error-message">{error}</div>}
          
          <form onSubmit={handleLogin}>
            <div className="input-group">
              <label className="input-label" htmlFor="email">E-posta</label>
              <input
                type="email"
                id="email"
                className="input-field"
                placeholder="ornek@haneyapim.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>

            <div className="input-group">
              <label className="input-label" htmlFor="password">Şifre</label>
              <div style={{ position: 'relative', width: '100%' }}>
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="password"
                  className="input-field"
                  style={{ paddingRight: '2.5rem', width: '100%', boxSizing: 'border-box' }}
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    position: 'absolute',
                    right: '0.75rem',
                    top: '50%',
                    transform: 'translateY(-50%)',
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    color: 'var(--color-text-muted)',
                    display: 'flex',
                    alignItems: 'center',
                    padding: 0
                  }}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <button 
              type="submit" 
              className="btn-primary" 
              disabled={isLoading || !email || !password}
            >
              {isLoading ? (
                <><span className="loader"></span> Giriş Yapılıyor...</>
              ) : (
                'Giriş Yap'
              )}
            </button>
          </form>
        </div>
      </main>
    </div>
  )
}
