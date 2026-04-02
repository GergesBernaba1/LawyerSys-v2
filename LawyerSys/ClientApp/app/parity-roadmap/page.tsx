'use client'

import { useEffect, useState } from 'react'
import ParityRoadmapTable from '../../src/components/parity/ParityRoadmapTable'
import ParityMetricsEditor from '../../src/components/parity/ParityMetricsEditor'
import ParityActionToolbar from '../../src/components/parity/ParityActionToolbar'
import { fetchParityRoadmapItems } from '../../src/services/parityService'
import type { RoadmapItem } from '../../src/types/parity'

export default function ParityRoadmapPage() {
  const [items, setItems] = useState<RoadmapItem[]>([])

  useEffect(() => {
    fetchParityRoadmapItems()
      .then(setItems)
      .catch(() => setItems([]))
  }, [])

  return (
    <main>
      <h1>Parity Roadmap</h1>
      <ParityActionToolbar canEdit />
      <ParityRoadmapTable items={items} />
      <ParityMetricsEditor onSubmit={() => undefined} />
    </main>
  )
}
