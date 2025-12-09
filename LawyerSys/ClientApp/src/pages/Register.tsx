import dynamic from 'next/dynamic'

const RegisterClient = dynamic(() => import('../client/Register.client'), { ssr: false })

export default RegisterClient
