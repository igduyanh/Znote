# 📓 ObsiNote — Ứng dụng ghi chú kiểu Obsidian

## 📌 Tổng quan dự án

| Thuộc tính       | Giá trị                              |
|------------------|--------------------------------------|
| Tên dự án        | ObsiNote                             |
| Loại             | Web App — Ghi chú liên kết           |
| Frontend         | Next.js 14 (App Router)              |
| Backend          | Next.js API Routes (Node.js)         |
| Database         | Supabase (PostgreSQL)                |
| Auth             | Supabase Auth (Email + Google OAuth) |
| Deploy           | Vercel                               |
| Giao diện        | Dark Navy + Vàng (#de9b35)           |
| Màu chính        | `#0a1628` (navy), `#de9b35` (vàng)   |

---

## 🎯 Tính năng cốt lõi (MVP)

### 1. 🔐 Authentication
- [x] Đăng ký / Đăng nhập bằng Email & Password
- [x] Đăng nhập bằng Google OAuth (Supabase)
- [x] Tự động đồng bộ tên/avatar từ Google account
- [x] Protected routes (middleware Next.js)
- [x] Session management qua Supabase Auth

### 2. 👥 Multi-user & Workspace
- [x] Mỗi user có workspace riêng biệt
- [x] Hệ thống **mã mời 6 chữ số** (tự động generate)
- [x] Người dùng có thể join workspace bằng mã mời
- [x] Phân quyền: Owner / Member
- [x] Quản lý thành viên trong workspace

### 3. 📁 Tổ chức Note
- [x] Tạo / Sửa / Xoá note
- [x] Tổ chức theo **Folder** (nested folders)
- [x] Gắn **Tags** cho note
- [x] Tìm kiếm note theo tên, tag, folder
- [x] Sidebar điều hướng folder/tags

### 4. ✏️ Editor
- [x] **Split-view**: Markdown editor bên trái + Preview bên phải
- [x] Syntax highlighting trong editor
- [x] Hỗ trợ **Markdown link** `[text](url)`
- [x] Hỗ trợ **[[Wiki-link]]** giữa các note
- [x] Toolbar Markdown (bold, italic, heading, link, code...)
- [x] Nút **Save/Sync** thủ công (không auto-save liên tục)

### 5. 🔗 Liên kết & Backlinks
- [x] Tạo liên kết giữa các note bằng `[text](note-id)` hoặc `[[note-title]]`
- [x] Hiển thị **Backlinks panel**: các note đang trỏ đến note hiện tại
- [x] Click link trong preview để navigate sang note đó

### 6. 🕸️ Graph View
- [x] Đồ thị visualisation các note và liên kết giữa chúng
- [x] Interactive: zoom, drag, click node để mở note
- [x] Màu node theo tags hoặc folder

---

## 🗃️ Cấu trúc Database (Supabase / PostgreSQL)

```sql
-- Users (handled by Supabase Auth)
-- profiles: thông tin bổ sung người dùng
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspaces
CREATE TABLE workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles(id),
  invite_code CHAR(6) UNIQUE NOT NULL, -- mã mời 6 chữ số
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspace Members
CREATE TABLE workspace_members (
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('owner', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (workspace_id, user_id)
);

-- Folders
CREATE TABLE folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES folders(id) ON DELETE CASCADE, -- nested folders
  name TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tags
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#de9b35',
  UNIQUE(workspace_id, name)
);

-- Notes
CREATE TABLE notes (
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

-- Note Tags (many-to-many)
CREATE TABLE note_tags (
  note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, tag_id)
);

-- Note Links (liên kết giữa các note)
CREATE TABLE note_links (
  source_note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  target_note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
  PRIMARY KEY (source_note_id, target_note_id)
);
```

---

## 📁 Cấu trúc thư mục dự án

```
obsinote/
├── app/                          # Next.js App Router
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx            # Layout chính với sidebar
│   │   ├── workspace/
│   │   │   ├── [workspaceId]/
│   │   │   │   ├── page.tsx      # Trang workspace
│   │   │   │   ├── note/
│   │   │   │   │   └── [noteId]/page.tsx  # Editor
│   │   │   │   └── graph/page.tsx         # Graph view
│   ├── api/
│   │   ├── workspaces/route.ts
│   │   ├── notes/route.ts
│   │   ├── notes/[id]/route.ts
│   │   ├── folders/route.ts
│   │   ├── tags/route.ts
│   │   ├── links/route.ts
│   │   └── invite/route.ts       # Mã mời workspace
│   └── layout.tsx
├── components/
│   ├── editor/
│   │   ├── MarkdownEditor.tsx    # CodeMirror editor
│   │   ├── MarkdownPreview.tsx   # Render Markdown
│   │   └── EditorToolbar.tsx
│   ├── sidebar/
│   │   ├── Sidebar.tsx
│   │   ├── FolderTree.tsx
│   │   └── TagList.tsx
│   ├── graph/
│   │   └── GraphView.tsx         # D3.js / react-force-graph
│   ├── backlinks/
│   │   └── BacklinksPanel.tsx
│   └── ui/                       # Shared UI components
│       ├── Button.tsx
│       ├── Modal.tsx
│       └── ...
├── lib/
│   ├── supabase/
│   │   ├── client.ts             # Browser client
│   │   ├── server.ts             # Server client
│   │   └── middleware.ts
│   ├── markdown/
│   │   ├── parser.ts             # Parse [[wiki-links]]
│   │   └── renderer.ts
│   └── utils.ts
├── hooks/
│   ├── useNote.ts
│   ├── useWorkspace.ts
│   └── useLinks.ts
├── types/
│   └── index.ts                  # TypeScript interfaces
├── styles/
│   └── globals.css               # Navy/yellow theme
├── supabase/
│   ├── migrations/               # SQL migrations
│   └── seed.sql
├── middleware.ts                 # Auth middleware
├── .env.local.example
├── PROJECT.md                    # File này
└── package.json
```

---

## 🎨 Design System

### Màu sắc
| Tên             | Hex       | Sử dụng                          |
|-----------------|-----------|----------------------------------|
| Navy Dark       | `#070f1c` | Background chính                 |
| Navy            | `#0a1628` | Background card, sidebar         |
| Navy Light      | `#0f2040` | Hover states, borders            |
| Navy Border     | `#1a3a5c` | Borders, dividers                |
| Gold Primary    | `#de9b35` | Accent chính, links, buttons     |
| Gold Light      | `#f0b85a` | Hover gold                       |
| Gold Dark       | `#b87d20` | Pressed gold                     |
| Text Primary    | `#e8edf5` | Text chính                       |
| Text Secondary  | `#8899aa` | Text phụ, placeholder            |
| Text Muted      | `#4a6080` | Disabled, muted                  |

### Typography
- Font chính: `Inter` (UI)
- Font editor: `JetBrains Mono` (code, markdown)

---

## 🛠️ Tech Stack chi tiết

| Layer        | Technology                    | Lý do chọn                         |
|--------------|-------------------------------|-------------------------------------|
| Frontend     | Next.js 14 (App Router)       | SSR, API routes, dễ deploy Vercel   |
| Styling      | Tailwind CSS                  | Nhanh, dễ custom theme              |
| Editor       | CodeMirror 6                  | Markdown, syntax highlight, extensible |
| Markdown     | `react-markdown` + `remark`   | Parse & render Markdown             |
| Graph        | `react-force-graph`           | D3-based, interactive               |
| Auth         | Supabase Auth                 | Email + Google OAuth built-in       |
| Database     | Supabase (PostgreSQL)         | RLS, real-time capable              |
| ORM/Query    | Supabase JS Client            | Type-safe, đơn giản                 |
| Icons        | Lucide React                  | Nhẹ, đẹp                           |
| Deploy       | Vercel                        | Zero-config Next.js                 |

---

## 📋 Task List (theo thứ tự triển khai)

### Phase 1: Setup & Foundation
- [ ] Khởi tạo Next.js 14 project với TypeScript + Tailwind
- [ ] Cấu hình Supabase project (tạo project trên supabase.com)
- [ ] Thiết lập theme Navy/Gold trong Tailwind config
- [ ] Tạo layout cơ bản (sidebar + main content)
- [ ] Cấu hình environment variables

### Phase 2: Database & Auth
- [ ] Tạo Supabase migrations (tất cả bảng)
- [ ] Cấu hình Row Level Security (RLS) policies
- [ ] Implement Auth: Email/Password login & register
- [ ] Implement Auth: Google OAuth
- [ ] Middleware bảo vệ routes
- [ ] Profile page & sync Google account info

### Phase 3: Workspace & Invite System
- [ ] CRUD Workspace
- [ ] Generate mã mời 6 chữ số ngẫu nhiên (unique)
- [ ] Join workspace bằng mã mời
- [ ] Quản lý thành viên (xem danh sách, kick member)
- [ ] Workspace switcher trong sidebar

### Phase 4: Folder & Tag System
- [ ] CRUD Folders (nested)
- [ ] Folder tree component trong sidebar
- [ ] CRUD Tags (với màu sắc)
- [ ] Gắn tag vào note
- [ ] Filter note theo folder/tag

### Phase 5: Note Editor (Core)
- [ ] Tạo / Xoá / Đổi tên note
- [ ] Split-view editor (CodeMirror + Preview)
- [ ] Markdown toolbar
- [ ] Render Markdown với `react-markdown`
- [ ] Nút Save/Sync thủ công
- [ ] Hiển thị trạng thái saved/unsaved

### Phase 6: Note Linking & Backlinks
- [ ] Parse `[[wiki-link]]` trong editor
- [ ] Gợi ý note khi gõ `[[`
- [ ] Lưu note_links vào database khi save
- [ ] Backlinks panel (hiển thị note nào trỏ đến note hiện tại)
- [ ] Click link trong preview để navigate

### Phase 7: Graph View
- [ ] Tích hợp `react-force-graph`
- [ ] Load nodes (notes) và edges (links) từ database
- [ ] Interactive: zoom, drag, click
- [ ] Style theo theme navy/gold

### Phase 8: Search
- [ ] Tìm kiếm note theo tên
- [ ] Tìm kiếm theo tag
- [ ] Full-text search trong nội dung (Supabase `tsvector`)
- [ ] Command palette (Ctrl+K)

### Phase 9: Polish & Deploy
- [ ] Responsive design
- [ ] Loading states, error handling
- [ ] Toast notifications
- [ ] Deploy lên Vercel
- [ ] Cấu hình Supabase production

---

## 🚀 Tính năng nâng cao (sau MVP)

| Tính năng            | Mô tả                                              | Độ phức tạp |
|----------------------|----------------------------------------------------|-------------|
| Templates            | Mẫu note có sẵn, tạo note từ template              | ⭐⭐         |
| Daily Notes          | Note tự động theo ngày (journal)                   | ⭐⭐         |
| Export PDF           | Xuất note ra file PDF                              | ⭐⭐⭐       |
| Export Markdown      | Tải về file .md                                    | ⭐          |
| Embed Image          | Upload & embed ảnh trong note (Supabase Storage)   | ⭐⭐⭐       |
| Version History      | Lịch sử chỉnh sửa, khôi phục phiên bản cũ         | ⭐⭐⭐⭐     |
| Real-time Collab     | Nhiều người cùng edit 1 note (Yjs/WebSocket)       | ⭐⭐⭐⭐⭐   |
| Kanban View          | Xem note dạng kanban board theo tag/status         | ⭐⭐⭐       |
| Note Pinning         | Ghim note quan trọng lên đầu                       | ⭐          |
| Custom Themes        | Người dùng tự chọn theme màu                       | ⭐⭐         |
| Mobile App           | React Native hoặc PWA                             | ⭐⭐⭐⭐     |
| AI Summary           | Tóm tắt note bằng AI (OpenAI API)                 | ⭐⭐⭐       |
| Webhook              | Trigger khi note được tạo/cập nhật                | ⭐⭐⭐       |

---

## ⚙️ Environment Variables

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Next.js
NEXTAUTH_SECRET=your_secret
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

---

## 🔐 Supabase RLS Policies (tóm tắt)

- **notes**: Chỉ members của workspace mới xem/sửa được
- **workspaces**: Owner mới xoá được workspace
- **workspace_members**: Chỉ owner mới thêm/xoá member
- **folders, tags**: Members của workspace có thể CRUD
- **profiles**: User chỉ sửa được profile của mình

---

## 📅 Lộ trình phát triển

```
Tuần 1: Phase 1 + 2 (Setup, Auth)
Tuần 2: Phase 3 + 4 (Workspace, Folders, Tags)
Tuần 3: Phase 5 + 6 (Editor, Linking)
Tuần 4: Phase 7 + 8 (Graph, Search)
Tuần 5: Phase 9 (Polish, Deploy)
```

---

## 📝 Ghi chú kỹ thuật

- **Invite code**: Generate bằng `Math.random()` + check unique trong DB, regenerate nếu trùng
- **Wiki-link parser**: Regex `\[\[([^\]]+)\]\]` để extract note titles, resolve thành note IDs
- **Note links**: Parse và sync vào bảng `note_links` mỗi khi user nhấn Save
- **Graph data**: Query join `notes` + `note_links` một lần, render client-side
- **RLS**: Dùng Supabase RLS + `auth.uid()` để bảo mật, không cần check thủ công trong API
- **Extensibility**: Mỗi tính năng mới = 1 route mới trong `app/api/` + component mới, không ảnh hưởng core

---

*Tạo lần đầu: 2026-03-12 | Phiên bản: 1.0.0*