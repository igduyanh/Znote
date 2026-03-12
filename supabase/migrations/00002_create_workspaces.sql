-- Migration: Create workspaces table
-- Description: Workspace - mỗi user có thể tạo/join nhiều workspace

CREATE TABLE IF NOT EXISTS workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  invite_code CHAR(6) UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Members can view their workspaces"
  ON workspaces FOR SELECT
  USING (
    id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create workspaces"
  ON workspaces FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Only owner can update workspace"
  ON workspaces FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Only owner can delete workspace"
  ON workspaces FOR DELETE
  USING (auth.uid() = owner_id);

-- Allow anyone to look up workspace by invite code (for joining)
CREATE POLICY "Anyone can lookup workspace by invite code"
  ON workspaces FOR SELECT
  USING (true);
