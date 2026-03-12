// TypeScript interfaces matching the database schema from PROJECT.md

export interface Profile {
  id: string
  full_name: string | null
  avatar_url: string | null
  created_at: string
}

export interface Workspace {
  id: string
  name: string
  owner_id: string
  invite_code: string
  created_at: string
}

export interface WorkspaceMember {
  workspace_id: string
  user_id: string
  role: 'owner' | 'member'
  joined_at: string
}

export interface Folder {
  id: string
  workspace_id: string
  parent_id: string | null
  name: string
  created_by: string
  created_at: string
}

export interface Tag {
  id: string
  workspace_id: string
  name: string
  color: string
}

export interface Note {
  id: string
  workspace_id: string
  folder_id: string | null
  title: string
  content: string
  created_by: string
  updated_by: string
  created_at: string
  updated_at: string
}

export interface NoteTag {
  note_id: string
  tag_id: string
}

export interface NoteLink {
  source_note_id: string
  target_note_id: string
}
