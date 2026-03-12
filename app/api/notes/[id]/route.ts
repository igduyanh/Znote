// TODO: Implement single note API (Phase 5)
import { NextResponse } from 'next/server'

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  return NextResponse.json({ message: `Note ${params.id} - Coming soon` })
}

export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  return NextResponse.json({ message: `Update note ${params.id} - Coming soon` })
}

export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  return NextResponse.json({ message: `Delete note ${params.id} - Coming soon` })
}
