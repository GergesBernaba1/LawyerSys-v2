@echo off
echo Starting LawyerSys ClientApp...
set NODE_ENV=production
set PORT=3002
set HOSTNAME=0.0.0.0
set NEXT_PUBLIC_BACKEND_URL=https://localhost:7001/api
node server.js
