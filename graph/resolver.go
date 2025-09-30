package graph

import (
	"sync"

	"github.com/jkzilla/egg/graph/model"
)

// This file will not be regenerated automatically.
//
// It serves as dependency injection for your app, add any dependencies you require here.

type Resolver struct{
	eggs  map[string]*model.Egg
	mutex sync.RWMutex
}

func NewResolver() *Resolver {
	return &Resolver{
		eggs: make(map[string]*model.Egg),
	}
}

func (r *Resolver) AddEgg(egg *model.Egg) {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	r.eggs[egg.ID] = egg
}
