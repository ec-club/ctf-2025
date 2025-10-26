package main

import (
	"bytes"
	"crypto/subtle"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	_ "github.com/lib/pq"
)

func getenv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func escapeLike(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, `%`, `\%`)
	s = strings.ReplaceAll(s, `_`, `\_`)
	return s
}

func combineFragments(frags ...[]byte) []byte {
	var b bytes.Buffer
	for _, f := range frags {
		b.Write(f)
	}
	return b.Bytes()
}

func rotateLeft(b byte, n uint) byte {
	n = n & 7
	return (b<<n | b>>(8-n)) & 0xFF
}

func rotXorTransform(input []byte, key []byte) []byte {
	out := make([]byte, len(input))
	keyLen := len(key)
	for i := range input {
		k := key[i%keyLen]
		x := input[i] ^ k
		out[i] = rotateLeft(x, uint(i%8))
	}
	return out
}

func main() {
	dbURL := getenv("DATABASE_URL", "postgres://postgres:postgrespassword@db:5432/challenge?sslmode=disable")

	overrideSecret := os.Getenv("SECRET")

	fragA := []byte{0x60, 0x08, 0x8e, 0x65}
	fragB := []byte{0x02, 0x68, 0xe7, 0x5d}
	fragC := []byte{0x76, 0xaa, 0xd6, 0xcd}
	fragD := []byte{0xc4, 0x68, 0xeb, 0xda}
	fragE := []byte{0x76, 0xb2}

	storedObf := combineFragments(fragA, fragB, fragC, fragD, fragE)

	key := []byte{0x13, 0x37, 0xC0, 0xDE}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("db open: %v", err)
	}
	defer db.Close()
	if err := db.Ping(); err != nil {
		log.Fatalf("db ping: %v", err)
	}

	http.HandleFunc("/search", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query().Get("q")
		debugParam := r.URL.Query().Get("__debug")

		checkPass := false
		if overrideSecret != "" {
			if debugParam == overrideSecret {
				checkPass = true
			}
		} else {
			if len(debugParam) > 0 {
				if len(debugParam) == len(storedObf) {
					candidateObf := rotXorTransform([]byte(debugParam), key)
					if subtle.ConstantTimeCompare(candidateObf, storedObf) == 1 {
						checkPass = true
					}
				}
			}
		}

		if checkPass {
			query := fmt.Sprintf("SELECT content FROM messages WHERE content LIKE '%%%s%%' LIMIT 20;", q)
			rows, err := db.Query(query)
			if err != nil {
				http.Error(w, "db err: "+err.Error(), http.StatusInternalServerError)
				return
			}
			defer rows.Close()
			var out []string
			for rows.Next() {
				var s string
				_ = rows.Scan(&s)
				out = append(out, s)
			}
			fmt.Fprintf(w, "DEBUG results:\n%s\n", strings.Join(out, "\n"))
			return
		}

		if len(q) < 3 {
			http.Error(w, "q parameter required (min length 3)", http.StatusBadRequest)
			return
		}
		escaped := escapeLike(q)
		likePattern := "%" + escaped + "%"

		rows, err := db.Query("SELECT content FROM messages WHERE content LIKE $1 ESCAPE '\\' AND content NOT LIKE 'CTF%' LIMIT 1", likePattern)
		if err != nil {
			http.Error(w, "db err", http.StatusInternalServerError)
			return
		}
		defer rows.Close()
		var out []string
		for rows.Next() {
			var s string
			_ = rows.Scan(&s)
			out = append(out, s)
		}
		fmt.Fprintf(w, "Here you go:\n%s\n", strings.Join(out, "\n"))
	})

	port := "8080"
	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
