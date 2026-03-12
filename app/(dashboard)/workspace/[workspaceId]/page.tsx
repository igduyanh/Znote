// TODO: Implement workspace page (Phase 3)
export default function WorkspacePage({
  params,
}: {
  params: { workspaceId: string }
}) {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold">Workspace</h1>
      <p className="mt-2 text-gray-500">Workspace ID: {params.workspaceId}</p>
      <p className="text-sm text-gray-400">Coming soon...</p>
    </div>
  )
}
