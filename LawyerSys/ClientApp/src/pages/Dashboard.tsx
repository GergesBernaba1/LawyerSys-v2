import dynamic from 'next/dynamic'

const DashboardClient = dynamic(() => import('../client/Dashboard.client'), { ssr: false })

export default DashboardClient
