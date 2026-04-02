type Props = {
  onSubmit: () => void
}

export default function ParityMetricsEditor({ onSubmit }: Props) {
  return (
    <section>
      <h2>Metrics</h2>
      <button type="button" onClick={onSubmit}>Save metric</button>
    </section>
  )
}
