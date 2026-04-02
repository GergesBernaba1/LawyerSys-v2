export type CoverageStatus = 'covered' | 'partially_covered' | 'missing'

export interface ParityCapability {
  capabilityId: string
  category: string
  title: string
  description?: string
  evidenceSourceUrl: string
  evidenceCapturedAt: string
  evidenceConfidence: 'low' | 'medium' | 'high'
  tenantScope: string
}

export interface CoverageAssessment {
  assessmentId: string
  capabilityId: string
  coverageStatus: CoverageStatus
  businessImpactScore: number
  customerDemandScore: number
  strategicRelevanceScore: number
  assessmentNotes?: string
  assessedByRole: string
  assessedByUserId: string
  assessedAt: string
}

export interface RoadmapItem {
  roadmapItemId: string
  itemType: 'parity' | 'improvement' | 'differentiation'
  priorityTier: 'P1' | 'P2' | 'P3'
  scopeLabel: 'in_scope' | 'deferred' | 'out_of_scope'
  lifecycleState: 'draft' | 'approved' | 'in_delivery' | 'released' | 'review_pending' | 'completed'
  problemStatement: string
  expectedUserOutcome: string
  ownerUserId?: string
}
