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
 * Tutar input'larında canlı binlik ayraç biçimlendirmesi (Türkiye biçimi:
 * nokta binlik ayraç, virgül ondalık ayraç — örn. "2.000.000,50").
 * Mobildeki `ThousandsSeparatorInputFormatter` ile aynı mantık.
 */
export function formatMoneyInput(rawText) {
  const clean = rawText.replace(/\./g, '')
  const commaIndex = clean.indexOf(',')
  const hasComma = commaIndex !== -1
  let intPart
  let decPart = ''
  if (hasComma) {
    intPart = clean.slice(0, commaIndex).replace(/[^0-9]/g, '')
    decPart = clean.slice(commaIndex + 1).replace(/[^0-9]/g, '').slice(0, 2)
  } else {
    intPart = clean.replace(/[^0-9]/g, '')
  }
  intPart = intPart.replace(/^0+(?=\d)/, '')

  let formatted = ''
  for (let i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 === 0) formatted += '.'
    formatted += intPart[i]
  }
  if (hasComma) formatted += `,${decPart}`
  return formatted
}

/** Binlik ayraçlı metni ("2.000.000,50") sayıya çevirir. */
export function parseMoneyInput(text) {
  if (!text) return 0
  const normalized = String(text).replace(/\./g, '').replace(',', '.')
  const n = parseFloat(normalized)
  return Number.isFinite(n) ? n : 0
}

/** Bir sayıyı, bir input'u başlangıçta doldururken kullanmak üzere binlik ayraçlı metne çevirir. */
export function formatAmountForDisplay(value) {
  const n = num(value)
  const isNegative = n < 0
  const intValue = Math.trunc(Math.abs(n))
  const hasDecimals = Math.abs(n) - intValue > 0.0001
  let formatted = String(intValue).replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  if (hasDecimals) {
    const decStr = (Math.abs(n) - intValue).toFixed(2).slice(2)
    formatted += `,${decStr}`
  }
  return isNegative ? `-${formatted}` : formatted
}

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

/** Mobildeki `CompanyProfile.isComplete` ile aynı: temel alanlar dolu mu. */
export const isProfileComplete = (p) => {
  if (!p) return false
  const req = ['company_name', 'tax_office', 'tax_number', 'commercial_registry', 'mersis_no',
    'address_line1', 'city', 'country', 'phone1', 'email']
  return req.every((k) => String(p[k] || '').trim().length > 0)
}

/** Varsayılan proje görseli (mobildeki bundled asset ile aynı; `public/` altında). */
export const DEFAULT_PROJECT_IMG = '/modern_apartment_building.png'

/** Projenin görsel URL'i: geçerli bir http(s) `image_path` varsa veya /media/ ile başlıyorsa onu, yoksa varsayılanı döndürür. */
export const projectImage = (project) => {
  const p = project?.image_path
  if (typeof p === 'string' && (/^https?:\/\//.test(p) || p.startsWith('/media/'))) {
    const base = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
      ? 'http://localhost:8000'
      : 'https://web-production-77031.up.railway.app';
    return p.startsWith('/media/') ? `${base}${p}` : p;
  }
  return DEFAULT_PROJECT_IMG
}
