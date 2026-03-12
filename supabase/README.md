# Supabase Setup Guide

## Cách chạy migrations

1. Truy cập Supabase Dashboard: https://supabase.com/dashboard
2. Chọn project của bạn
3. Vào SQL Editor
4. Chạy lần lượt các file migration theo thứ tự:
   - 00001_create_profiles.sql
   - 00002_create_workspaces.sql
   - 00003_create_workspace_members.sql
   - 00004_create_folders.sql
   - 00005_create_tags.sql
   - 00006_create_notes.sql
   - 00007_create_note_tags.sql
   - 00008_create_note_links.sql

Hoặc chạy file ALL-IN-ONE:
   - 00000_full_schema.sql

## Lưu ý
- Chạy đúng thứ tự vì có foreign key dependencies
- File 00001 có trigger tự tạo profile khi user đăng ký
- Tất cả bảng đều có RLS (Row Level Security) enabled
