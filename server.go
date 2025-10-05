package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/playground"
	"github.com/jkzilla/egg/graph"
	"github.com/jkzilla/egg/graph/model"
	"github.com/rs/cors"
)

const defaultPort = "8080"

// corsMiddleware adds CORS headers to allow frontend access
func corsMiddleware(next http.Handler) http.Handler {
	c := cors.New(cors.Options{
		AllowedOrigins: []string{
			"https://haileysgarden.com",
			"https://www.haileysgarden.com",
			"http://localhost:5173", // Local development
		},
		AllowedMethods:   []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})
	return c.Handler(next)
}

// spaHandler implements the http.Handler interface for serving a SPA
type spaHandler struct {
	staticPath string
	indexPath  string
}

func (h spaHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := filepath.Join(h.staticPath, r.URL.Path)

	// Check if file exists
	_, err := os.Stat(path)
	if os.IsNotExist(err) {
		// File does not exist, serve index.html
		http.ServeFile(w, r, filepath.Join(h.staticPath, h.indexPath))
		return
	} else if err != nil {
		// Other error
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// File exists, serve it
	http.FileServer(http.Dir(h.staticPath)).ServeHTTP(w, r)
}

// startServer runs the GraphQL API server
func startServer() {
	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}

	// Create resolver with sample data
	resolver := graph.NewResolver()

	// Add sample eggs - sold by half dozen or dozen
	resolver.AddEgg(&model.Egg{
		ID:                "1",
		Type:              "Half Dozen Eggs",
		Price:             4.00,
		QuantityAvailable: 4,
		Description:       strPtr("6 fresh farm eggs, assorted colors from free-range chickens"),
	})
	resolver.AddEgg(&model.Egg{
		ID:                "2",
		Type:              "Dozen Eggs",
		Price:             7.50,
		QuantityAvailable: 2,
		Description:       strPtr("12 fresh farm eggs, assorted colors from free-range chickens"),
	})

	srv := handler.NewDefaultServer(graph.NewExecutableSchema(graph.Config{Resolvers: resolver}))

	// GraphQL endpoints
	http.Handle("/graphql", corsMiddleware(srv))
	http.Handle("/playground", playground.Handler("GraphQL playground", "/graphql"))

	// Serve static files from frontend/dist
	spa := spaHandler{staticPath: "frontend/dist", indexPath: "index.html"}
	http.Handle("/", spa)

	log.Printf("Server starting on http://localhost:%s", port)
	log.Printf("GraphQL playground: http://localhost:%s/playground", port)
	log.Printf("Frontend: http://localhost:%s/", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func strPtr(s string) *string {
	return &s
}
