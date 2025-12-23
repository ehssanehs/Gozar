package gozar

import (
    "context"
    "sync"
    "time"
)

type Controller struct {
    mu   sync.Mutex
    ctx  context.Context
    stop context.CancelFunc
}

func NewController() *Controller {
    return &Controller{}
}

func (c *Controller) Start(configJson string) bool {
    c.mu.Lock()
    defer c.mu.Unlock()
    if c.stop != nil {
        return true
    }
    c.ctx, c.stop = context.WithCancel(context.Background())
    // TODO: parse configJson and initialize xray-core runtime
    time.Sleep(50 * time.Millisecond)
    return true
}

func (c *Controller) Stop() {
    c.mu.Lock()
    defer c.mu.Unlock()
    if c.stop != nil {
        c.stop()
        c.stop = nil
    }
}
