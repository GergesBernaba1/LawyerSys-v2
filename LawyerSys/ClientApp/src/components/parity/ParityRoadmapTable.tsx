import type { RoadmapItem } from '../../types/parity'

type Props = {
  items: RoadmapItem[]
}

export default function ParityRoadmapTable({ items }: Props) {
  if (!items.length) {
    return <p>No roadmap items yet.</p>
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Type</th>
          <th>Priority</th>
          <th>Scope</th>
          <th>State</th>
        </tr>
      </thead>
      <tbody>
        {items.map((item) => (
          <tr key={item.roadmapItemId}>
            <td>{item.itemType}</td>
            <td>{item.priorityTier}</td>
            <td>{item.scopeLabel}</td>
            <td>{item.lifecycleState}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
