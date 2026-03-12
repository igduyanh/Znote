-- Migration: Create note_tags table
-- Description: Many-to-many relationship giữa notes và tags

CREATE TABLE IF NOT EXISTS note_tags (
  note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, tag_id)
);

-- Enable RLS
ALTER TABLE note_tags ENABLE ROW LEVEL SECURITY;

-- RLS Policies (dựa vào workspace membership thông qua note)
CREATE POLICY "Workspace members can view note tags"
  ON note_tags FOR SELECT
  USING (
    note_id IN (
      SELECT id FROM notes WHERE workspace_id IN (
        SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Workspace members can add tags to notes"
  ON note_tags FOR INSERT
  WITH CHECK (
    note_id IN (
      SELECT id FROM notes WHERE workspace_id IN (
        SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Workspace members can remove tags from notes"
  ON note_tags FOR DELETE
  USING (
    note_id IN (
      SELECT id FROM notes WHERE workspace_id IN (
        SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
      )
    )
  );
