-- Migration: Create note_links table
-- Description: Liên kết giữa các note (cho wiki-links và graph view)

CREATE TABLE IF NOT EXISTS note_links (
  source_note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  target_note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  PRIMARY KEY (source_note_id, target_note_id)
);

-- Enable RLS
ALTER TABLE note_links ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Workspace members can view note links"
  ON note_links FOR SELECT
  USING (
    source_note_id IN (
      SELECT id FROM notes WHERE workspace_id IN (
        SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Workspace members can create note links"
  ON note_links FOR INSERT
  WITH CHECK (
    source_note_id IN (
      SELECT id FROM notes WHERE workspace_id IN (
        SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Workspace members can delete note links"
  ON note_links FOR DELETE
  USING (
    source_note_id IN (
      SELECT id FROM notes WHERE workspace_id IN (
        SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
      )
    )
  );

-- Indexes for graph queries
CREATE INDEX IF NOT EXISTS idx_note_links_source ON note_links(source_note_id);
CREATE INDEX IF NOT EXISTS idx_note_links_target ON note_links(target_note_id);
