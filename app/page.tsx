// Home page - redirect to login or dashboard
// TODO: Implement redirect logic based on auth state (Phase 2)
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center">
      <h1 className="text-4xl font-bold">📓 ObsiNote</h1>
      <p className="mt-4 text-lg text-gray-500">Ứng dụng ghi chú liên kết kiểu Obsidian</p>
      <p className="mt-2 text-sm text-gray-400">Coming soon...</p>
    </main>
  )
}
