package gozar

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"sync"

	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"
)

type Controller struct {
	mu     sync.Mutex
	ctx    context.Context
	cancel context.CancelFunc
	inst   *core.Instance
}

func NewController() *Controller { return &Controller{} }

// Start loads the provided Xray JSON config and starts the runtime.
// If already started, this is a no-op.
// It also sets XRAY_LOCATION_ASSET from the "gozarAssetDir" field in the JSON, if present.
func (c *Controller) Start(configJSON string) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.inst != nil {
		return nil
	}

	// Extract asset dir hint from JSON for XRAY_LOCATION_ASSET
	var meta struct {
		GozarAssetDir string `json:"gozarAssetDir"`
	}
	_ = json.Unmarshal([]byte(configJSON), &meta)
	if meta.GozarAssetDir != "" {
		_ = os.Setenv("XRAY_LOCATION_ASSET", meta.GozarAssetDir)
	}

	cfg, err := serial.LoadJSON(bytes.NewReader([]byte(configJSON)))
	if err != nil {
		return err
	}

	c.ctx, c.cancel = context.WithCancel(context.Background())
	inst, err := core.New(c.ctx, cfg)
	if err != nil {
		if c.cancel != nil {
			c.cancel()
			c.cancel = nil
		}
		return err
	}
	if err := inst.Start(); err != nil {
		_ = inst.Close()
		if c.cancel != nil {
			c.cancel()
			c.cancel = nil
		}
		return err
	}

	c.inst = inst
	return nil
}

func (c *Controller) Stop() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.inst != nil {
		_ = c.inst.Close()
		c.inst = nil
	}
	if c.cancel != nil {
		c.cancel()
		c.cancel = nil
	}
}
