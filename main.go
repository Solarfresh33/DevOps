package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func ping(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet || r.URL.Path != "/ping" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(r.Header)
}

func main() {
	port := os.Getenv("PING_LISTEN_PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", ping)

	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}