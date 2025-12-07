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
