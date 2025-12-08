import React from 'react'
import { Routes, Route } from 'react-router-dom'
import { ThemeProvider, CssBaseline } from '@mui/material'
import theme from './theme'
import Layout from './components/Layout'
import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import Cases from './pages/Cases'
import Customers from './pages/Customers'
import Employees from './pages/Employees'
import Files from './pages/Files'
import Courts from './pages/Courts'
import Contenders from './pages/Contenders'
import Sitings from './pages/Sitings'
import Consultations from './pages/Consultations'
import JudicialDocuments from './pages/JudicialDocuments'
import AdminTasks from './pages/AdminTasks'
import Billing from './pages/Billing'
import LegacyUsers from './pages/LegacyUsers'
import CaseRelations from './pages/CaseRelations'
import Governments from './pages/Governments'
import { AuthProvider } from './services/auth'

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/cases" element={<Cases />} />
            <Route path="/customers" element={<Customers />} />
            <Route path="/employees" element={<Employees />} />
            <Route path="/files" element={<Files />} />
            <Route path="/courts" element={<Courts />} />
            <Route path="/contenders" element={<Contenders />} />
            <Route path="/sitings" element={<Sitings />} />
            <Route path="/consultations" element={<Consultations />} />
            <Route path="/judicial" element={<JudicialDocuments />} />
            <Route path="/tasks" element={<AdminTasks />} />
            <Route path="/billing" element={<Billing />} />
            <Route path="/legacyusers" element={<LegacyUsers />} />
            <Route path="/governments" element={<Governments />} />
            <Route path="/caserelations" element={<CaseRelations />} />
          </Routes>
        </Layout>
      </AuthProvider>
    </ThemeProvider>
  )
}
