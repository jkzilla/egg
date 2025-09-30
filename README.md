# egg
An application written in Go, using GraphQL, that will assist you in setting up a page for small-scale farming selling eggs.

## Getting Started

### Prerequisites
- Go 1.19 or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/jkzilla/egg.git
cd egg
```

2. Install dependencies:
```bash
go mod download
```

3. Build the application:
```bash
go build -o egg .
```

4. Run the application:
```bash
./egg
```

The GraphQL server will start on `http://localhost:8080/`

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
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"query":"{ eggs { id type price quantityAvailable description } }"}'
```

**Purchase eggs:**
```bash
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { purchaseEgg(id: \"1\", quantity: 6) { success message remainingQuantity } }"}'
```

### GraphQL Playground

Visit `http://localhost:8080/` in your browser to access the GraphQL Playground, where you can interactively explore the API and test queries.

### Sample Data

The application comes pre-loaded with sample eggs:
- Brown Chicken Egg - $0.50 each (24 available)
- White Chicken Egg - $0.45 each (36 available)
- Duck Egg - $1.25 each (12 available)
- Quail Egg - $0.75 each (48 available)

## Development

### Regenerating GraphQL Code

If you modify the GraphQL schema in `graph/schema.graphqls`, regenerate the code:

```bash
go run github.com/99designs/gqlgen generate
```

### Configuration

The server port can be configured using the `PORT` environment variable:

```bash
PORT=3000 ./egg
```
