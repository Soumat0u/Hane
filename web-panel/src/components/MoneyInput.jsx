import { useRef } from 'react'
import { formatMoneyInput } from '../utils'

/**
 * Tutar input'u: yazarken otomatik binlik ayraç ekler (2.000.000,50).
 * `value`/`onChange` string tutar; kaydetmeden önce `parseMoneyInput` ile sayıya çevirin.
 */
export default function MoneyInput({ value, onChange, className = 'form-input', style, ...rest }) {
  const inputRef = useRef(null)

  const handleChange = (e) => {
    const el = e.target
    const cursor = el.selectionStart ?? el.value.length
    const meaningfulBeforeCursor = el.value.slice(0, cursor).replace(/\./g, '').length
    const formatted = formatMoneyInput(el.value)

    onChange(formatted)

    requestAnimationFrame(() => {
      if (!inputRef.current) return
      let newOffset = formatted.length
      let count = 0
      for (let i = 0; i < formatted.length; i++) {
        if (count >= meaningfulBeforeCursor) { newOffset = i; break }
        if (formatted[i] !== '.') count++
        newOffset = i + 1
      }
      inputRef.current.setSelectionRange(newOffset, newOffset)
    })
  }

  return (
    <input
      ref={inputRef}
      className={className}
      style={style}
      type="text"
      inputMode="decimal"
      value={value}
      onChange={handleChange}
      {...rest}
    />
  )
}
