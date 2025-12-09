"use client"
import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import App from '../App'

export default function AppClientWrapper({ basename = '' }: { basename?: string }) {
  return (
    <BrowserRouter basename={basename}>
      <App />
    </BrowserRouter>
  )
}
