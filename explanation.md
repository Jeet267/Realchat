# Realchat Architecture & Explanation

## Architecture
Realchat is a full-stack real-time application structured into two primary workspaces:
- **Frontend**: A React application powered by Vite, utilizing `zustand` for state management, `react-router` for navigation, and `stream-chat-react` for chat UI elements. Styling is handled via TailwindCSS and DaisyUI.
- **Backend**: A Node.js/Express application connecting to MongoDB (via Mongoose). It implements the Stream Chat SDK to handle real-time messaging logic and provides REST API endpoints for authentication and user management.

## Workflow & CI/CD
The project employs a robust CI/CD pipeline integrated with GitHub Actions:
- **Linting & Formatting**: Enforced via ESLint and Prettier.
- **Unit & Integration Testing**: The frontend uses Vitest with React Testing Library, and the backend uses Jest with Supertest.
- **E2E Testing**: Cypress is integrated to simulate user flows (e.g., login).
- **CI Workflow**: Triggers on `push` and `pull_request`, running tests and linters in isolation for both frontend and backend matrices.
- **CD Workflow**: A deployment pipeline uses SSH to connect to an AWS EC2 instance and execute an idempotent deployment bash script (`scripts/deploy.sh`).
- **Dependabot**: Configured to check for outdated npm packages weekly.

## Design Decisions
1. **Separation of Concerns**: Kept the frontend and backend strictly decoupled.
2. **Testing Strategy**: Used Vitest for Vite environments because it executes faster and natively supports ES modules without complex Babel configurations, whereas Jest is used for the Node backend.
3. **Idempotency**: Wrote deployment scripts using fallbacks (e.g., `mkdir -p`, `pm2 restart || pm2 start`) to ensure scripts can be run sequentially without errors regardless of prior state.

## Challenges
- Mocking ES modules directly in Node/Jest without transpilation steps required using `--experimental-vm-modules` to support modern syntax natively.
- Combining disparate backend packages in integration tests required carefully mocking the Mongoose model layers so development and CI environments wouldn't hang searching for actual database connections unexpectedly.
