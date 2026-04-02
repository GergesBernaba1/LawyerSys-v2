import api, { PARITY_API_ROUTES } from './api'
import type { ParityCapability, RoadmapItem } from '../types/parity'

export async function fetchParityCapabilities(): Promise<ParityCapability[]> {
  const { data } = await api.get<ParityCapability[]>(PARITY_API_ROUTES.capabilities)
  return data
}

export async function fetchParityRoadmapItems(): Promise<RoadmapItem[]> {
  const { data } = await api.get<RoadmapItem[]>(PARITY_API_ROUTES.roadmapItems)
  return data
}
