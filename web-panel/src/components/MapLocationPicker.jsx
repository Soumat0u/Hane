import { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { X, MapPin } from 'lucide-react'

/**
 * Mobildeki `MapLocationPicker` ekranının web karşılığı: OpenStreetMap
 * (Leaflet, API anahtarı gerektirmez) üzerinde harita ortasındaki pin'i
 * sürükleyerek konum seçilir, onaylanınca Nominatim ile il/ilçe adına
 * çözümlenip metin olarak döner.
 */
export default function MapLocationPicker({ onClose, onSelect }) {
  const mapRef = useRef(null)
  const mapInstanceRef = useRef(null)
  const [center, setCenter] = useState({ lat: 39.9208, lng: 32.8541 }) // Ankara
  const [resolving, setResolving] = useState(false)

  useEffect(() => {
    if (mapInstanceRef.current) return
    const map = L.map(mapRef.current, { center: [center.lat, center.lng], zoom: 6 })
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map)
    map.on('moveend', () => {
      const c = map.getCenter()
      setCenter({ lat: c.lat, lng: c.lng })
    })
    mapInstanceRef.current = map
    // Modal içinde açılırken doğru boyutu almasını sağla.
    setTimeout(() => map.invalidateSize(), 50)
    return () => {
      map.remove()
      mapInstanceRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleConfirm = async () => {
    setResolving(true)
    let result = `${center.lat.toFixed(5)}, ${center.lng.toFixed(5)}`
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${center.lat}&lon=${center.lng}&zoom=18&accept-language=tr`,
      )
      const data = await res.json()
      const addr = data?.address
      if (addr) {
        const parts = [
          addr.road,
          addr.neighbourhood || addr.suburb,
          addr.county || addr.town || addr.city_district,
          addr.city || addr.province || addr.state
        ].filter(Boolean);
        if (parts.length > 0) result = parts.join(', ');
      }
    } catch {
      // Reverse geocoding başarısız olursa koordinatları kullan.
    } finally {
      setResolving(false)
    }
    onSelect(result)
  }

  return createPortal(
    <div className="modal-overlay">
      {/* React portal'ları DOM ağacı dışına render edilse de olay yayılımı (bubbling)
          bileşen ağacını takip eder — bu yüzden burada durdurulmazsa her tıklama üst
          bileşenin (ProjectFormModal) "dışına tıklayınca kapat" davranışına kadar yayılıp
          tüm proje formunu kapatır (harita sürüklenirken de aynı şekilde tetiklenir). */}
      <div
        className="modal"
        style={{ maxWidth: 640, height: '80vh', display: 'flex', flexDirection: 'column' }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal-header">
          <span className="modal-title">Haritadan Konum Seç</span>
          <button className="modal-close" onClick={onClose}><X size={20} /></button>
        </div>
        <div style={{ position: 'relative', flex: 1 }}>
          <div ref={mapRef} style={{ position: 'absolute', inset: 0 }} />
          <div style={{
            position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -100%)',
            pointerEvents: 'none', zIndex: 1000,
          }}>
            <MapPin size={40} color="var(--color-accent)" fill="var(--color-accent)" fillOpacity={0.15} />
          </div>
        </div>
        <div className="modal-footer">
          <button className="btn-secondary" onClick={onClose}>İptal</button>
          <button className="btn-primary" style={{ width: 'auto', marginTop: 0 }} onClick={handleConfirm} disabled={resolving}>
            {resolving ? <span className="loader" /> : 'Bu Konumu Seç'}
          </button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
