// TODO: Implement dashboard layout with sidebar (Phase 1.4)
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex min-h-screen">
      <aside className="w-64 border-r">
        {/* Sidebar placeholder */}
        <div className="p-4">
          <p className="text-sm text-gray-500">Sidebar - Coming soon</p>
        </div>
      </aside>
      <main className="flex-1">{children}</main>
    </div>
  )
}
