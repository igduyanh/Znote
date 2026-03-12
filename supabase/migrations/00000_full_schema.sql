-- ===========================================
-- ObsiNote - Full Schema (ALL-IN-ONE)
-- ===========================================
-- File này chứa toàn bộ SQL migrations từ 00001 đến 00008
-- Chạy file này nếu muốn tạo toàn bộ schema cùng lúc
-- Hoặc chạy từng file riêng lẻ theo thứ tự để dễ debug

-- -------------------------------------------
-- SECTION 1: Profiles
-- -------------------------------------------
-- Migration: Create profiles table
-- Description: Thông tin bổ sung người dùng, liên kết với Supabase Auth

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- User chỉ xem được profile của mình và các members trong cùng workspace
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Function: Tự động tạo profile khi user đăng ký
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Tự động gọi function khi có user mới
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -------------------------------------------
-- SECTION 2: Workspaces
-- -------------------------------------------
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

-- -------------------------------------------
-- SECTION 3: Workspace Members
-- -------------------------------------------
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

-- -------------------------------------------
-- SECTION 4: Folders
-- -------------------------------------------
-- Migration: Create folders table
-- Description: Hệ thống folder lồng nhau (nested folders) trong workspace

CREATE TABLE IF NOT EXISTS folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES folders(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Workspace members can view folders"
  ON folders FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can create folders"
  ON folders FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can update folders"
  ON folders FOR UPDATE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can delete folders"
  ON folders FOR DELETE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

-- -------------------------------------------
-- SECTION 5: Tags
-- -------------------------------------------
-- Migration: Create tags table
-- Description: Tags với màu sắc, unique per workspace

CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#de9b35',
  UNIQUE(workspace_id, name)
);

-- Enable RLS
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Workspace members can view tags"
  ON tags FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can create tags"
  ON tags FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can update tags"
  ON tags FOR UPDATE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can delete tags"
  ON tags FOR DELETE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

-- -------------------------------------------
-- SECTION 6: Notes
-- -------------------------------------------
-- Migration: Create notes table
-- Description: Bảng notes chính - lưu nội dung ghi chú Markdown

CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
  title TEXT NOT NULL DEFAULT 'Untitled',
  content TEXT DEFAULT '',
  created_by UUID REFERENCES profiles(id),
  updated_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Workspace members can view notes"
  ON notes FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can create notes"
  ON notes FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can update notes"
  ON notes FOR UPDATE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can delete notes"
  ON notes FOR DELETE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid()
    )
  );

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_notes_workspace_id ON notes(workspace_id);
CREATE INDEX IF NOT EXISTS idx_notes_folder_id ON notes(folder_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_by ON notes(created_by);

-- Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -------------------------------------------
-- SECTION 7: Note Tags
-- -------------------------------------------
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

-- -------------------------------------------
-- SECTION 8: Note Links
-- -------------------------------------------
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
