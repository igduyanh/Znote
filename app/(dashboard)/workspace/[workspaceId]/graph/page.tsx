// TODO: Implement graph view page (Phase 7)
export default function GraphViewPage({
  params,
}: {
  params: { workspaceId: string }
}) {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold">Graph View</h1>
      <p className="mt-2 text-gray-500">Workspace: {params.workspaceId}</p>
      <p className="text-sm text-gray-400">Coming soon...</p>
    </div>
  )
}
