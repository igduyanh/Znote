-- Migration: Create workspace_members table
-- Description: Many-to-many relationship giữa users và workspaces

CREATE TABLE IF NOT EXISTS workspace_members (
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('owner', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (workspace_id, user_id)
);

-- Enable RLS
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Members can view workspace members"
  ON workspace_members FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace owner can add members"
  ON workspace_members FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT owner_id FROM workspaces WHERE id = workspace_id
    )
    OR auth.uid() = user_id  -- user tự join bằng invite code
  );

CREATE POLICY "Workspace owner can remove members"
  ON workspace_members FOR DELETE
  USING (
    auth.uid() IN (
      SELECT owner_id FROM workspaces WHERE id = workspace_id
    )
  );
