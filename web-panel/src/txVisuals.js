import { ArrowUp, ArrowDown, ArrowLeftRight, Landmark } from 'lucide-react'

/** Gelir sayılan işlem tipleri (özet ve bakiye hesabında kullanılır). */
export const INCOME_TYPES = new Set(['Gelir', 'Tahsilat', 'Satış'])

/**
 * Bir işlem tipinin rengi ve ikonu (liste + detay ekranı paylaşır).
 * Mobil `transactionVisuals` ile birebir eşleşir.
 */
export function txVisuals(type) {
  if (type === 'Gider') return { color: 'var(--color-danger)', Icon: ArrowUp }
  if (INCOME_TYPES.has(type)) return { color: 'var(--color-success)', Icon: ArrowDown }
  if (type === 'Transfer') return { color: 'var(--color-accent)', Icon: ArrowLeftRight }
  // Borçlanma, Kredi Kullanımı vb.
  return { color: 'var(--color-warning)', Icon: Landmark }
}
