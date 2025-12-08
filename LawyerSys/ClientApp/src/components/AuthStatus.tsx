import React from 'react'
import { useAuth } from '../services/auth'

function parseTokenUser(token?:string|null){
  if (!token) return null
  try{
    const payload = token.split('.')[1]
    const json = JSON.parse(atob(payload))
    return json.unique_name || json.uniqueName || json.sub || null
  }catch{ return null }
}

export default function AuthStatus(){
  const { token, logout } = useAuth()
  const user = parseTokenUser(token)

  return (
    <div style={{display:'flex',alignItems:'center',gap:8}}>
      {token ? (
        <>
          <div>Signed in as <b>{user ?? 'user'}</b></div>
          <button className="btn" onClick={logout}>Sign out</button>
        </>
      ) : (
        <div style={{color:'#666'}}>Not signed in</div>
      )}
    </div>
  )
}
