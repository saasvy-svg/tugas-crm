'use client'

import { useTransition, useRef } from 'react'
import { Loader2 } from 'lucide-react'

interface LoginFormProps {
  loginAction: (formData: FormData) => Promise<void>
  errorMessage?: string
}

export default function LoginForm({ loginAction, errorMessage }: LoginFormProps) {
  const [isPending, startTransition] = useTransition()
  const formRef = useRef<HTMLFormElement>(null)

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (isPending) return
    const formData = new FormData(e.currentTarget)
    startTransition(async () => {
      await loginAction(formData)
    })
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      formRef.current?.requestSubmit()
    }
  }

  return (
    <form ref={formRef} onSubmit={handleSubmit} className="space-y-5">
      {/* Email */}
      <div>
        <label
          htmlFor="login-email"
          className="block text-xs font-semibold uppercase tracking-widest text-slate-500 mb-1.5"
        >
          Email Pekerjaan
        </label>
        <input
          id="login-email"
          name="email"
          type="email"
          autoComplete="email"
          required
          disabled={isPending}
          onKeyDown={handleKeyDown}
          placeholder="staff@agensi.com"
          className="w-full px-4 py-3.5 rounded-xl bg-white/50 border border-indigo-100/50 text-sm text-slate-800 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:bg-white transition-all duration-150 shadow-sm disabled:opacity-50"
        />
      </div>

      {/* Password */}
      <div>
        <label
          htmlFor="login-password"
          className="block text-xs font-semibold uppercase tracking-widest text-slate-500 mb-1.5"
        >
          Kata Sandi
        </label>
        <input
          id="login-password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          disabled={isPending}
          onKeyDown={handleKeyDown}
          placeholder="••••••••••"
          className="w-full px-4 py-3.5 rounded-xl bg-white/50 border border-indigo-100/50 text-sm text-slate-800 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:bg-white transition-all duration-150 shadow-sm disabled:opacity-50"
        />
      </div>

      {/* Error message */}
      {errorMessage && (
        <div
          role="alert"
          className="flex items-start gap-3 bg-rose-50/80 backdrop-blur-sm border border-rose-100 text-rose-600 text-sm p-3.5 rounded-xl"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="w-4 h-4 mt-0.5 shrink-0 text-rose-500"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <span>{decodeURIComponent(errorMessage)}</span>
        </div>
      )}

      {/* Submit */}
      <button
        id="login-submit-button"
        type="submit"
        disabled={isPending}
        className="w-full bg-gradient-to-r from-violet-600 to-indigo-600 hover:from-violet-700 hover:to-indigo-700 active:scale-[0.98] text-white font-semibold py-3.5 rounded-xl transition-all duration-200 shadow-lg shadow-violet-500/25 mt-2 focus:outline-none focus:ring-2 focus:ring-violet-500/50 flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed cursor-pointer"
      >
        {isPending ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            <span>Memproses Masuk...</span>
          </>
        ) : (
          <span>Mulai Bekerja</span>
        )}
      </button>
    </form>
  )
}
