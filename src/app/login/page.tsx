import { login } from './actions'
import LoginForm from './LoginForm'

export const metadata = {
  title: 'Masuk — Vylogix CRM & Client Portal',
  description: 'Masuk ke portal Vylogix Studio untuk mengelola proyek dan melihat laporan perkembangan.',
}

/**
 * LoginPage renders a clean, full-screen portal access form.
 *
 * Authentication flow:
 *   1. User submits email + password via a Server Action form.
 *   2. `login()` server action authenticates with Supabase, reads the role
 *      from the `profiles` table, and redirects to the correct dashboard.
 *   3. If already authenticated, the middleware intercepts and redirects
 *      before this page component is ever rendered.
 */
export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ message?: string }>
}) {
  const resolvedParams = await searchParams
  const errorMessage = resolvedParams?.message

  return (
    <div className="relative min-h-screen flex flex-col items-center justify-center p-4 py-8 sm:py-12 overflow-hidden bg-white">
      {/* ── Background Gradients ── */}
      <div className="absolute top-0 -left-4 w-72 h-72 bg-purple-300 rounded-full mix-blend-multiply filter blur-2xl opacity-30 animate-blob" />
      <div className="absolute top-0 -right-4 w-72 h-72 bg-indigo-300 rounded-full mix-blend-multiply filter blur-2xl opacity-30 animate-blob animation-delay-2000" />
      <div className="absolute -bottom-8 left-20 w-72 h-72 bg-pink-300 rounded-full mix-blend-multiply filter blur-2xl opacity-30 animate-blob animation-delay-4000" />

      <div className="relative z-10 w-full flex flex-col items-center">
        {/* ── Brand Header ── */}
        <div className="mb-6 text-center select-none">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-br from-violet-600 to-indigo-600 shadow-lg shadow-indigo-500/30 mb-4 transform -rotate-3 hover:rotate-0 transition-transform duration-300">
            {/* Building Workspace Icon */}
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="w-7 h-7 text-white"
              aria-hidden="true"
            >
              <rect x="4" y="2" width="16" height="20" rx="2" ry="2" />
              <path d="M9 22v-4h6v4" />
              <path d="M8 6h.01" />
              <path d="M16 6h.01" />
              <path d="M12 6h.01" />
              <path d="M12 10h.01" />
              <path d="M12 14h.01" />
              <path d="M16 10h.01" />
              <path d="M16 14h.01" />
              <path d="M8 10h.01" />
              <path d="M8 14h.01" />
            </svg>
          </div>
          <h1 className="text-3xl sm:text-4xl font-extrabold text-slate-800 tracking-tight">
            Agency <span className="text-transparent bg-clip-text bg-gradient-to-r from-violet-600 to-indigo-600">Workspace</span>
          </h1>
          <p className="mt-1.5 text-sm text-slate-500">
            Masuk ke ruang kerja operasional tim Anda.
          </p>
        </div>

        {/* ── Container with Fast Account Switcher & Login Form ── */}
        <div className="w-full max-w-4xl flex flex-col items-center">

          {/* ── Card ── */}
          <div className="w-full max-w-md bg-white/80 backdrop-blur-xl rounded-3xl border border-white/50 shadow-2xl shadow-indigo-900/5 p-8">
            <LoginForm loginAction={login} errorMessage={errorMessage} />
          </div>
        </div>

        {/* ── Footer ── */}
        <p className="mt-8 text-xs text-slate-400 text-center">
          &copy; {new Date().getFullYear()} Vylogix Studio. Agency & Team Portal.
        </p>
      </div>
    </div>
  )
}

