package tgbot

import "sync"

// MessageMemory stores the last N messages per chat in a thread-safe ring buffer.
type MessageMemory struct {
	mu    sync.RWMutex
	cap   int
	store map[int64]*ringBuffer
}

type Message struct {
	Role    string
	Content string
}

type ringBuffer struct {
	data  []Message
	start int // index of oldest
	count int // number of valid elements
}

func newRingBuffer(capacity int) *ringBuffer {
	return &ringBuffer{data: make([]Message, capacity)}
}

func (rb *ringBuffer) push(msg Message) {
	if len(rb.data) == 0 {
		return
	}
	if rb.count < len(rb.data) {
		idx := (rb.start + rb.count) % len(rb.data)
		rb.data[idx] = msg
		rb.count++
		return
	}
	// overwrite oldest
	rb.data[rb.start] = msg
	rb.start = (rb.start + 1) % len(rb.data)
}

func (rb *ringBuffer) snapshot() []Message {
	out := make([]Message, rb.count)
	for i := 0; i < rb.count; i++ {
		out[i] = rb.data[(rb.start+i)%len(rb.data)]
	}
	return out
}

func (rb *ringBuffer) lastN(n int) []Message {
	if n <= 0 || rb.count == 0 {
		return nil
	}
	if n > rb.count {
		n = rb.count
	}
	start := (rb.start + rb.count - n) % len(rb.data)
	out := make([]Message, n)
	for i := 0; i < n; i++ {
		out[i] = rb.data[(start+i)%len(rb.data)]
	}
	return out
}

func (rb *ringBuffer) clear() {
	// Zero for GC
	for i := 0; i < rb.count; i++ {
		rb.data[(rb.start+i)%len(rb.data)] = Message{}
	}
	rb.start = 0
	rb.count = 0
}

// NewMessageMemory creates a memory with capacity for the last N messages per chat.
func NewMessageMemory(capacity int) *MessageMemory {
	if capacity < 1 {
		capacity = 1
	}
	return &MessageMemory{
		cap:   capacity,
		store: make(map[int64]*ringBuffer),
	}
}

// Add appends a message to the chat's memory, evicting the oldest when full.
func (m *MessageMemory) Add(chatID int64, message Message) {
	m.mu.Lock()
	defer m.mu.Unlock()
	rb := m.store[chatID]
	if rb == nil {
		rb = newRingBuffer(m.cap)
		m.store[chatID] = rb
	}
	rb.push(message)
}

// Get returns all messages for a chat in chronological order (oldest to newest).
func (m *MessageMemory) Get(chatID int64) []Message {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if rb := m.store[chatID]; rb != nil {
		return rb.snapshot()
	}
	return nil
}

// GetLast returns the last n messages for a chat in chronological order.
func (m *MessageMemory) GetLast(chatID int64, n int) []Message {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if rb := m.store[chatID]; rb != nil {
		return rb.lastN(n)
	}
	return nil
}

// Clear removes all remembered messages for a chat.
func (m *MessageMemory) Clear(chatID int64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if rb := m.store[chatID]; rb != nil {
		rb.clear()
	}
}

// Delete removes the chat's buffer entirely.
func (m *MessageMemory) Delete(chatID int64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.store, chatID)
}
