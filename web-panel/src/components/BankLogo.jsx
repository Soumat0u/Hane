import { Landmark } from 'lucide-react'

// Mobil uygulamadaki `lib/views/widgets/bank_logo.dart` ile birebir aynı eşleme.
// Logo dosyaları `public/logos/` altında, mobildeki `assets/images/logos/` ile aynı PNG'ler.
function logoPathFor(bankName) {
  // JS'in varsayılan toLowerCase()'i Türkçe noktalı "İ" harfini doğru çevirmez
  // ("İş" -> "i̇ş" olur, "iş" değil); bu yüzden tr-TR yerel ayarı zorunlu.
  const lower = (bankName || '').toLocaleLowerCase('tr-TR')
  if (lower.includes('ziraat')) return '/logos/ziraat.png'
  if (lower.includes('garanti')) return '/logos/garanti.png'
  if (lower.includes('halk')) return '/logos/halk.png'
  if (lower.includes('akbank')) return '/logos/akbank.png'
  if (lower.includes('yapı kredi') || lower.includes('yapi kredi')) return '/logos/yapi_kredi.png'
  if (lower.includes('iş bankası') || lower.includes('is bankasi')) return '/logos/is_bankasi.png'
  if (lower.includes('vakıf') || lower.includes('vakif')) return '/logos/vakif.png'
  if (lower.includes('deniz')) return '/logos/denizbank.png'
  if (lower.includes('enpara')) return '/logos/enpara.png'
  if (lower.includes('qnb') || lower.includes('finansbank')) return '/logos/qnb.png'
  if (lower.includes('teb') || lower.includes('türk ekonomi')) return '/logos/teb.png'
  if (lower.includes('ing')) return '/logos/ing.png'
  if (lower.includes('hsbc')) return '/logos/hsbc.png'
  if (lower.includes('şeker') || lower.includes('seker')) return '/logos/sekerbank.png'
  if (lower.includes('odea')) return '/logos/odeabank.png'
  if (lower.includes('fiba')) return '/logos/fibabanka.png'
  if (lower.includes('anadolubank') || lower.includes('anadolu bank')) return '/logos/anadolubank.png'
  if (lower.includes('alternatif')) return '/logos/alternatifbank.png'
  if (lower.includes('kuveyt')) return '/logos/kuveytturk.png'
  if (lower.includes('albaraka') || lower.includes('al baraka')) return '/logos/albaraka.png'
  if (lower.includes('türkiye finans') || lower.includes('turkiye finans')) return '/logos/turkiyefinans.png'
  if (lower.includes('amex') || lower.includes('american express')) return '/logos/amex.png'
  if (lower.includes('visa')) return '/logos/visa.png'
  if (lower.includes('mastercard') || lower.includes('master card')) return '/logos/mastercard.png'
  if (lower.includes('troy')) return '/logos/troy.png'
  return null
}

export default function BankLogo({ bankName, width = 70, height = 30, className = '' }) {
  const path = logoPathFor(bankName)
  if (!path) {
    return (
      <div
        className={className}
        style={{ width, height, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-text-secondary)' }}
      >
        <Landmark size={Math.min(width, height) * 0.7} />
      </div>
    )
  }
  return (
    <div
      className={className}
      style={{
        width,
        height,
        padding: 2,
        background: '#fff',
        borderRadius: 4,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
      }}
    >
      <img src={path} alt={bankName || 'Banka'} style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }} />
    </div>
  )
}
