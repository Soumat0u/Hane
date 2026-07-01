// Ortak yardımcılar — Projeler ve Proje Detay sayfalarında paylaşılır.

const _tlFormatter = new Intl.NumberFormat('tr-TR', {
  style: 'currency',
  currency: 'TRY',
  maximumFractionDigits: 2,
})

const _numFormatter = new Intl.NumberFormat('tr-TR', { maximumFractionDigits: 2 })

/** Sayıya güvenli çevrim (API amount alanı string gelebilir). */
export const num = (x) => {
  const n = Number(x)
  return Number.isFinite(n) ? n : 0
}

/** TRY para birimi biçimlendirme (mobil `currencyFormat` ile aynı sonuç). */
export const formatCurrency = (val) => _tlFormatter.format(num(val))

/** Para birimi simgesi olmadan sayı (ör. Alan m²). */
export const formatNumber = (val) => _numFormatter.format(num(val))

/**
 * Mobildeki `status_color_hex` çözümlemesinin web karşılığı.
 * `#`, `0x`/`0xFF` öneklerini temizler, 8 haneli ise alfayı düşürür ve
 * son 6 hex haneyi `#rrggbb` olarak döndürür. Geçersizse nötr gri.
 */
export const parseStatusColor = (hex) => {
  if (!hex) return '#64748b'
  let c = String(hex).trim().replace('#', '').replace(/^0x/i, '')
  if (c.length === 8) c = c.slice(2) // ffRRGGBB → RRGGBB
  if (c.length < 6) return '#64748b'
  c = c.slice(-6)
  return /^[0-9a-fA-F]{6}$/.test(c) ? `#${c}` : '#64748b'
}

/** Rozet arka planı için ~%15 alfalı ton (mobil `withValues(alpha: 0.15)`). */
export const withAlpha15 = (hexColor) => `${hexColor}26`

/** Varsayılan proje görseli (mobildeki bundled asset ile aynı; `public/` altında). */
export const DEFAULT_PROJECT_IMG = '/modern_apartment_building.png'

/** Projenin görsel URL'i: geçerli bir http(s) `image_path` varsa onu, yoksa varsayılanı döndürür. */
export const projectImage = (project) => {
  const p = project?.image_path
  return typeof p === 'string' && /^https?:\/\//.test(p) ? p : DEFAULT_PROJECT_IMG
}
