# Hailey's Garden - Egg Shop

A full-stack application for selling farm-fresh eggs, featuring a Go GraphQL backend and a modern React TypeScript frontend with a beautiful, responsive UI.

## Features

- 🥚 **Product Catalog**: Browse different types of eggs with prices and availability
- 🛒 **Shopping Cart**: Add items to cart, adjust quantities, and checkout
- 💳 **Real-time Inventory**: Automatic inventory updates after purchases
- 🎨 **Modern UI**: Beautiful, responsive design with TailwindCSS
- 🚀 **GraphQL API**: Efficient data fetching with Apollo Client
- 🐳 **Docker Support**: Easy deployment with multi-stage builds

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

The application comes pre-loaded with sample eggs:
- Brown Chicken Egg - $0.50 each (24 available)
- White Chicken Egg - $0.45 each (36 available)
- Duck Egg - $1.25 each (12 available)
- Quail Egg - $0.75 each (48 available)

## Production Deployment

### Using Docker

Build and run the application with Docker:

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
npm run dev      # Start dev server
npm run build    # Build for production
npm run preview  # Preview production build
npm run lint     # Run ESLint
```

## API Endpoints

- `/` - Frontend application (production)
- `/graphql` - GraphQL API endpoint
- `/playground` - GraphQL Playground (interactive API explorer)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.
