package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestPing(t *testing.T) {
	cases := []struct {
		method, path string
		want         int
	}{
		{http.MethodGet, "/ping", http.StatusOK},
		{http.MethodPost, "/ping", http.StatusNotFound},
		{http.MethodGet, "/", http.StatusNotFound},
		{http.MethodGet, "/ping/", http.StatusNotFound},
	}

	for _, c := range cases {
		rec := httptest.NewRecorder()
		ping(rec, httptest.NewRequest(c.method, c.path, nil))

		if rec.Code != c.want {
			t.Errorf("%s %s: got %d, want %d", c.method, c.path, rec.Code, c.want)
		}
		if c.want == http.StatusNotFound && rec.Body.Len() != 0 {
			t.Errorf("%s %s: body should be empty, got %q", c.method, c.path, rec.Body.String())
		}
	}
}

func TestPingReturnsRequestHeaders(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/ping", nil)
	req.Header.Set("X-Test", "hi")
	rec := httptest.NewRecorder()
	ping(rec, req)

	var got map[string][]string
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatal(err)
	}
	if len(got["X-Test"]) == 0 || got["X-Test"][0] != "hi" {
		t.Errorf("request header not echoed back: %v", got)
	}
}