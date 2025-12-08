# LawyerSys Client (Admin UI)

This ClientApp is a small React + Vite admin UI created to interact with the LawyerSys API in the same repository.

Quick start:

1. Open a terminal and change into the client folder:

```bash
cd "LawyerSys/ClientApp"
```

2. Install dependencies (npm or yarn):

```bash
npm install
# or: yarn
```

3. Start the dev server (default port 5173):

```bash
npm run dev
```

By default the client targets `http://localhost:5000/api` — to change that, set environment variable `VITE_API_BASE_URL` (for example: `VITE_API_BASE_URL=http://localhost:5000/api npm run dev`).

Environment (.env)
-------------------

Create a local `.env` file in the `ClientApp` directory to override the defaults and keep secrets out of source control. A safe template is provided as `.env.example` — copy it and update any values you need:

```bash
cd "LawyerSys/ClientApp"
copy .env.example .env   # Windows (cmd.exe)
# or: cp .env.example .env   # macOS / Linux
```

Important: `.env` is ignored by git (local-only) — don't commit private keys or secrets.

Troubleshooting: ETARGET errors
--------------------------------

If you see an error like "ETARGET No matching version found for @vitejs/plugin-react@^5.2.0" when running `npm install`, an installed package version doesn't exist on the registry. Try the following:

1. Inspect available versions:

```bash
npm view @vitejs/plugin-react versions --json
```

2. Edit `package.json` and set a compatible version found in the list (example: `"@vitejs/plugin-react": "^4.0.0"`).

3. Clean npm cache and try again:

```bash
npm cache clean --force
npm install
```

If you still have problems, share the `npm` output and I can pick a compatible plugin version and update `package.json` for you.

Pages implemented so far:
- Login / Register (Identity)
- Cases (list, create, delete)
- Customers (list, create, delete)
- Employees (list, create, delete)
- Files (list, upload, delete)
 - Courts (list, create, delete)
 - Contenders (list, create, delete)
 - Sitings (list, create, delete)
 - Consultations (list, create, delete)
 - Judicial Documents (list, create, delete)
 - Admin Tasks (list, create, delete)
 - Billing (payments / receipts: list, create, delete)
 - Legacy Users (list, create, delete)
 - Case Relations (view/add/remove relationships between case and customers/contenders/courts/employees/sitings/files)
# ClientApp (React)

This is the React client app for LawyerSys. For a quick start we use Vite + React.

To create the app locally (one-time):

```cmd
cd ClientApp
npx create-vite@latest . --template react
npm install
npm run dev
```

Or use create-react-app if you prefer CRA.

Important: the API base url should be configured in an .env file or in package.json proxy during development.
