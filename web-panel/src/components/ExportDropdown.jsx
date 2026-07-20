import { useState, useRef, useEffect } from 'react'
import { FileDown, FileText, Table } from 'lucide-react'

export default function ExportDropdown({ onExportPDF, onExportExcel, style, btnClassName = 'icon-btn' }) {
  const [open, setOpen] = useState(false)
  const dropdownRef = useRef(null)

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  return (
    <div ref={dropdownRef} style={{ position: 'relative', display: 'inline-flex', ...style }}>
      <button
        className={btnClassName}
        onClick={() => setOpen(!open)}
        title="Dışa Aktar"
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '0.25rem',
          padding: '6px'
        }}
      >
        <FileDown size={18} />
      </button>

      {open && (
        <div style={{
          position: 'absolute',
          top: '100%',
          right: 0,
          marginTop: '0.5rem',
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          borderRadius: '0.5rem',
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
          minWidth: '160px',
          zIndex: 50,
          padding: '0.25rem',
          display: 'flex',
          flexDirection: 'column',
          gap: '2px'
        }}>
          <button
            onClick={() => {
              setOpen(false)
              if (onExportPDF) onExportPDF()
            }}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              width: '100%',
              padding: '0.5rem 0.75rem',
              border: 'none',
              background: 'transparent',
              textAlign: 'left',
              fontSize: '0.875rem',
              cursor: 'pointer',
              color: 'var(--color-text)',
              borderRadius: '0.25rem'
            }}
            onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'var(--color-background)'}
            onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
          >
            <FileText size={16} style={{ color: 'var(--color-danger)' }} />
            PDF Olarak
          </button>
          <button
            onClick={() => {
              setOpen(false)
              if (onExportExcel) onExportExcel()
            }}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              width: '100%',
              padding: '0.5rem 0.75rem',
              border: 'none',
              background: 'transparent',
              textAlign: 'left',
              fontSize: '0.875rem',
              cursor: 'pointer',
              color: 'var(--color-text)',
              borderRadius: '0.25rem'
            }}
            onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'var(--color-background)'}
            onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
          >
            <Table size={16} style={{ color: 'var(--color-success)' }} />
            Excel Olarak
          </button>
        </div>
      )}
    </div>
  )
}
