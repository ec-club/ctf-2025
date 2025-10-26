package web

import (
	"log"
	"sync"

	"github.com/sixafter/nanoid"
)

type LoginManager struct {
	mu       sync.Mutex
	requests map[string]chan bool
	nextID   int
}

func NewLoginManager() *LoginManager {
	return &LoginManager{
		requests: make(map[string]chan bool),
	}
}

func (lm *LoginManager) RequestLogin(notifier chan bool) string {
	lm.mu.Lock()
	defer lm.mu.Unlock()

	requestID := nanoid.Must().String()
	lm.requests[requestID] = notifier
	return requestID
}
func (lm *LoginManager) ApproveLogin(requestID string) {
	lm.mu.Lock()
	defer lm.mu.Unlock()

	if notifier, exists := lm.requests[requestID]; exists {
		log.Printf("Approving login request %s", requestID)
		notifier <- true
		close(notifier)
		delete(lm.requests, requestID)
	}
}
func (lm *LoginManager) InvalidateLoginRequest(requestID string) {
	lm.mu.Lock()
	defer lm.mu.Unlock()

	if notifier, exists := lm.requests[requestID]; exists {
		close(notifier)
		delete(lm.requests, requestID)
	}
}
