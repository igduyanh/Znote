// Shared Button component
// TODO: Enhance with variants and styles (Phase 1.3)
'use client'

import { ButtonHTMLAttributes } from 'react'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost'
}

export default function Button({ children, variant = 'primary', className = '', ...props }: ButtonProps) {
  return (
    <button className={`rounded px-4 py-2 ${className}`} {...props}>
      {children}
    </button>
  )
}
