type Props = {
  canEdit: boolean
}

export default function ParityActionToolbar({ canEdit }: Props) {
  return (
    <section>
      <button type="button" disabled={!canEdit}>Lock</button>
      <button type="button" disabled={!canEdit}>Refresh</button>
    </section>
  )
}
