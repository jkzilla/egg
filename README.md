# Hailey's Garden - Egg Shop

[![CircleCI](https://circleci.com/gh/jkzilla/egg.svg?style=svg)](https://circleci.com/gh/jkzilla/egg)

A full-stack application for selling farm-fresh eggs, featuring a Go 1.25 GraphQL backend and a modern React TypeScript frontend with a beautiful, responsive UI.

## Features

- 🥚 **Product Catalog**: Browse different types of eggs with prices and availability
- 🛒 **Shopping Cart**: Add items to cart, adjust quantities, and checkout
- 💳 **Real-time Inventory**: Automatic inventory updates after purchases
- 🎨 **Modern UI**: Beautiful, responsive design with TailwindCSS
- 🚀 **GraphQL API**: Efficient data fetching with Apollo Client
- 🐳 **Docker Support**: Easy deployment with multi-stage builds
- 🔒 **Security Scanning**: TruffleHog integration for secret detection
- 🔄 **CI/CD Pipeline**: Automated testing and deployment with CircleCI

## Tech Stack

### Backend
- **Go 1.22+**: High-performance backend
- **gqlgen**: GraphQL server implementation
- **CORS Support**: Cross-origin resource sharing enabled

### Frontend
- **React 18**: Modern UI framework
- **TypeScript**: Type-safe development
- **Vite**: Fast build tool and dev server
- **Apollo Client**: GraphQL client
- **TailwindCSS**: Utility-first CSS framework
- **Lucide React**: Beautiful icon library

## Getting Started

### Prerequisites
- Go 1.22 or higher
- Node.js 20 or higher
- npm or yarn

### Development Setup

1. **Clone the repository:**
```bash
git clone https://github.com/jkzilla/egg.git
cd egg
```

2. **Install backend dependencies:**
```bash
go mod download
```

3. **Install frontend dependencies:**
```bash
cd frontend
npm install
cd ..
```

4. **Run in development mode:**

In one terminal, start the backend:
```bash
go run .
```

In another terminal, start the frontend dev server:
```bash
cd frontend
npm run dev
```

The backend will run on `http://localhost:8080` and the frontend on `http://localhost:5173`

### Usage

The application provides a GraphQL API with the following features:

#### Queries

**Get all eggs:**
```graphql
query {
  eggs {
    id
    type
    price
    quantityAvailable
    description
  }
}
```

**Get a specific egg by ID:**
```graphql
query {
  egg(id: "1") {
    id
    type
    price
    quantityAvailable
    description
  }
}
```

#### Mutations

**Purchase eggs:**
```graphql
mutation {
  purchaseEgg(id: "1", quantity: 6) {
    success
    message
    remainingQuantity
  }
}
```

### Example Using cURL

**Query all eggs:**
```bash
curl -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ eggs { id type price quantityAvailable description } }"}'
```

**Purchase eggs:**
```bash
curl -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { purchaseEgg(id: \"1\", quantity: 6) { success message remainingQuantity } }"}'
```

### GraphQL Playground

Visit `http://localhost:8080/playground` in your browser to access the GraphQL Playground, where you can interactively explore the API and test queries.

### Sample Data

The application comes pre-loaded with sample products:
- Half Dozen Eggs - $4.00 (20 available)
- Dozen Eggs - $7.50 (15 available)

## Production Deployment

### Deploy to Netlify (Frontend) + Render/Railway (Backend)

For a complete guide on deploying the frontend to Netlify and backend to cloud platforms, see:

**📘 [NETLIFY_DEPLOY.md](./NETLIFY_DEPLOY.md)** - Complete deployment guide with step-by-step instructions

**Quick Start:**
1. Deploy backend to [Render](https://render.com/) or [Railway](https://railway.app/)
2. Deploy frontend to [Netlify](https://netlify.com/)
3. Set `VITE_GRAPHQL_ENDPOINT` environment variable on Netlify
4. Update CORS settings in backend

### Using Docker

Build and run the full-stack application with Docker:

```bash
# Build the image
docker build -t egg-shop .

# Run the container
docker run -p 8080:8080 egg-shop
```

The application will be available at `http://localhost:8080`

### Using Docker Compose

```bash
docker-compose up
```

### Building for Production

To build the frontend and backend separately:

```bash
# Build frontend
cd frontend
npm run build

# Build backend
go build -o egg .

# Run
./egg
```

## Development

### Project Structure

```
egg/
├── frontend/              # React TypeScript frontend
│   ├── src/
│   │   ├── components/   # React components
│   │   ├── graphql/      # GraphQL queries and mutations
│   │   ├── App.tsx       # Main app component
│   │   ├── main.tsx      # Entry point
│   │   └── types.ts      # TypeScript types
│   ├── public/           # Static assets
│   └── package.json      # Frontend dependencies
├── graph/                # GraphQL schema and resolvers
│   ├── schema.graphqls   # GraphQL schema definition
│   ├── resolver.go       # Resolver implementation
│   └── model/            # Generated models
├── main.go               # Application entry point
├── server.go             # HTTP server and routing
└── Dockerfile            # Multi-stage Docker build
```

### Regenerating GraphQL Code

If you modify the GraphQL schema in `graph/schema.graphqls`, regenerate the code:

```bash
go run github.com/99designs/gqlgen generate
```

### Configuration

The server port can be configured using the `PORT` environment variable:

```bash
PORT=3000 go run .
```

### Frontend Development

The frontend uses Vite for fast development with hot module replacement:

```bash
cd frontend
npm run dev          # Start dev server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
npm run test:e2e     # Run E2E tests (headless)
npm run test:e2e:ui  # Run E2E tests with UI
npm run test:e2e:headed  # Run E2E tests in browser
```

### E2E Testing

The project includes five comprehensive UI tests using Playwright:

1. **Page Load Test** - Verifies the page loads and displays egg products
2. **Add to Cart Test** - Tests adding items to the shopping cart
3. **Cart Display Test** - Validates cart sidebar opens and shows items
4. **Quantity Update Test** - Tests updating item quantities in cart
5. **Clear Cart Test** - Verifies clearing all items from cart

**Setup E2E Tests:**
```bash
cd frontend
npm install
npx playwright install chromium
npm run test:e2e
```

**View Test Report:**
```bash
npx playwright show-report
```

## API Endpoints

- `/` - Frontend application (production)
- `/graphql` - GraphQL API endpoint
- `/playground` - GraphQL Playground (interactive API explorer)

## CI/CD Pipeline

### CircleCI Integration

This project uses CircleCI for continuous integration and deployment. The pipeline includes:

**Automated Checks:**
- 🔒 Security scanning with TruffleHog
- 🧪 Backend unit tests with coverage reports
- ⚛️ Frontend build and linting
- 🔗 Integration tests for GraphQL API
- 🐳 Docker image builds and testing

**Pipeline Stages:**
1. **Security Scan** - Detects secrets and credentials
2. **Parallel Builds** - Backend and frontend build simultaneously
3. **Integration Tests** - End-to-end API validation
4. **Docker Build** - Multi-stage container build (main/master/develop only)

**Setup CircleCI:**
1. Connect your repository at [circleci.com](https://circleci.com/)
2. Add Docker Hub credentials (optional):
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
3. Pipeline runs automatically on every push and PR

See [`.circleci/README.md`](.circleci/README.md) for detailed configuration documentation.

## Security

### Secret Scanning with TruffleHog

This project uses [TruffleHog](https://github.com/trufflesecurity/trufflehog) to scan for accidentally committed secrets, API keys, and credentials.

#### Installation

Install TruffleHog using the provided script:

```bash
./scripts/install-trufflehog.sh
```

Or install manually:

**macOS (Homebrew):**
```bash
brew install trufflehog
```

**Linux/macOS (curl):**
```bash
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
```

#### Manual Scanning

Scan the entire repository:

```bash
trufflehog git file://. --only-verified
```

Scan since last commit:

```bash
trufflehog git file://. --since-commit HEAD --only-verified
```

#### Pre-commit Hooks

Set up automatic scanning before each commit:

```bash
# Install pre-commit
pip install pre-commit

# Install the hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

#### GitHub Actions

TruffleHog runs automatically on:
- Every push to `main`, `master`, or `develop` branches
- Every pull request
- Manual workflow dispatch

View results in the **Actions** tab on GitHub.

#### Configuration

TruffleHog settings are in `.trufflehog.yaml`:
- Excluded paths (node_modules, dist, etc.)
- Excluded file extensions
- Verification settings

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Note:** All commits are scanned for secrets. Ensure no sensitive data is committed.

## License

This project is licensed under the MIT License.
