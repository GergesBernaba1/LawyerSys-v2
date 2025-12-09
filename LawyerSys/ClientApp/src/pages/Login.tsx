import dynamic from 'next/dynamic'

const LoginClient = dynamic(() => import('../client/Login.client'), { ssr: false })

export default LoginClient
