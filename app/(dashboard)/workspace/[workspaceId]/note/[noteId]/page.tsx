// TODO: Implement note editor page (Phase 5)
export default function NoteEditorPage({
  params,
}: {
  params: { workspaceId: string; noteId: string }
}) {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold">Note Editor</h1>
      <p className="mt-2 text-gray-500">Note ID: {params.noteId}</p>
      <p className="text-sm text-gray-400">Coming soon...</p>
    </div>
  )
}
