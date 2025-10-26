package tgbot

import (
	"sync"
	"time"
)

type UserState string

const (
	StateUnknown  UserState = "unknown"
	StateRejected UserState = "rejected"
	StateApproved UserState = "approved"
)

type UserMemory struct {
	State      UserState
	RejectedAt time.Time
}

type StateManager struct {
	mu       sync.RWMutex
	memories map[int64]*UserMemory
}

func NewStateManager() *StateManager {
	return &StateManager{
		memories: make(map[int64]*UserMemory),
	}
}

func (sm *StateManager) SetRejected(userID int64) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.memories[userID] = &UserMemory{
		State:      StateRejected,
		RejectedAt: time.Now(),
	}
}

func (sm *StateManager) SetApproved(userID int64) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.memories[userID] = &UserMemory{
		State: StateApproved,
	}
}

func (sm *StateManager) GetState(userID int64) UserState {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	memory, exists := sm.memories[userID]
	if !exists {
		return StateUnknown
	}

	if memory.State == StateRejected {
		if time.Since(memory.RejectedAt) > 5*time.Minute {
			return StateUnknown
		}
	}

	return memory.State
}

func (sm *StateManager) IsRejected(userID int64) bool {
	return sm.GetState(userID) == StateRejected
}

func (sm *StateManager) IsApproved(userID int64) bool {
	return sm.GetState(userID) == StateApproved
}
