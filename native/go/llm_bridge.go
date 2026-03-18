package main

// #include <stdint.h>
// #include <stdlib.h>
import "C"

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"sync/atomic"

	"github.com/getkawai/unillm"
	"github.com/getkawai/unillm/providers/openrouter"
	"github.com/kawai-network/x/llm"
)

type generateTextRequest struct {
	Prompt          string   `json:"prompt"`
	System          string   `json:"system,omitempty"`
	TaskName        string   `json:"task_name,omitempty"`
	MaxOutputTokens *int64   `json:"max_output_tokens,omitempty"`
	Temperature     *float64 `json:"temperature,omitempty"`
	TopP            *float64 `json:"top_p,omitempty"`
	TopK            *int64   `json:"top_k,omitempty"`
}

type generateTextResult struct {
	Text         string              `json:"text"`
	FinishReason unillm.FinishReason `json:"finish_reason"`
	Usage        unillm.Usage        `json:"usage"`
	Model        string              `json:"model"`
	Provider     string              `json:"provider"`
}

type streamPartResult struct {
	Type             unillm.StreamPartType `json:"type"`
	ID               string                `json:"id,omitempty"`
	ToolCallName     string                `json:"tool_call_name,omitempty"`
	ToolCallInput    string                `json:"tool_call_input,omitempty"`
	Delta            string                `json:"delta,omitempty"`
	ProviderExecuted bool                  `json:"provider_executed,omitempty"`
	Usage            unillm.Usage          `json:"usage,omitempty"`
	FinishReason     unillm.FinishReason   `json:"finish_reason,omitempty"`
	Error            string                `json:"error,omitempty"`
	SourceType       unillm.SourceType     `json:"source_type,omitempty"`
	URL              string                `json:"url,omitempty"`
	Title            string                `json:"title,omitempty"`
}

type streamState struct {
	ch   chan unillm.StreamPart
	done chan struct{}
	err  atomic.Value // string
}

var (
	streamHandles   = map[uint64]*streamState{}
	streamHandlesMu sync.RWMutex
	streamSeq       uint64
)

func nextStreamHandle(s *streamState) uint64 {
	handle := atomic.AddUint64(&streamSeq, 1)
	streamHandlesMu.Lock()
	streamHandles[handle] = s
	streamHandlesMu.Unlock()
	return handle
}

func getStreamHandle(handle uint64) (*streamState, error) {
	streamHandlesMu.RLock()
	s := streamHandles[handle]
	streamHandlesMu.RUnlock()
	if s == nil {
		return nil, errors.New("invalid stream handle")
	}
	return s, nil
}

func deleteStreamHandle(handle uint64) {
	streamHandlesMu.Lock()
	delete(streamHandles, handle)
	streamHandlesMu.Unlock()
}

func buildPrompt(req generateTextRequest) (unillm.Prompt, error) {
	if req.Prompt == "" {
		return nil, errors.New("prompt is required")
	}
	prompt := make(unillm.Prompt, 0, 2)
	if req.System != "" {
		prompt = append(prompt, unillm.Message{
			Role: unillm.MessageRoleSystem,
			Content: []unillm.MessagePart{
				unillm.TextPart{Text: req.System},
			},
		})
	}
	prompt = append(prompt, unillm.Message{
		Role: unillm.MessageRoleUser,
		Content: []unillm.MessagePart{
			unillm.TextPart{Text: req.Prompt},
		},
	})
	return prompt, nil
}

func buildCriteria() openrouter.ModelSelectionCriteria {
	return openrouter.ModelSelectionCriteria{
		RequireReasoning:   false,
		RequireAttachments: false,
		MinContextWindow:   4096,
	}
}

//export LLMGenerateTextJSON
func LLMGenerateTextJSON(input *C.char) *C.char {
	if input == nil {
		return responseCString(jsonResponse{Ok: false, Error: "input is required"})
	}

	var req generateTextRequest
	if err := json.Unmarshal([]byte(C.GoString(input)), &req); err != nil {
		return responseCString(jsonResponse{Ok: false, Error: "invalid JSON input"})
	}

	prompt, err := buildPrompt(req)
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}

	taskName := req.TaskName
	if taskName == "" {
		taskName = "dart_go_bridge"
	}

	model := llm.BuildChain(llm.ModelChainConfig{
		Context:  context.Background(),
		TaskName: taskName,
		Criteria: buildCriteria(),
	})
	if model == nil {
		return responseCString(jsonResponse{Ok: false, Error: "no model chain available (check API keys)"})
	}

	call := unillm.Call{
		Prompt:          prompt,
		MaxOutputTokens: req.MaxOutputTokens,
		Temperature:     req.Temperature,
		TopP:            req.TopP,
		TopK:            req.TopK,
	}

	resp, err := model.Generate(context.Background(), call)
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}

	result := generateTextResult{
		Text:         resp.Content.Text(),
		FinishReason: resp.FinishReason,
		Usage:        resp.Usage,
		Model:        model.Model(),
		Provider:     model.Provider(),
	}

	return responseCString(jsonResponse{Ok: true, Data: result})
}

//export LLMStreamStartJSON
func LLMStreamStartJSON(input *C.char) *C.char {
	if input == nil {
		return responseCString(jsonResponse{Ok: false, Error: "input is required"})
	}

	var req generateTextRequest
	if err := json.Unmarshal([]byte(C.GoString(input)), &req); err != nil {
		return responseCString(jsonResponse{Ok: false, Error: "invalid JSON input"})
	}

	prompt, err := buildPrompt(req)
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}

	taskName := req.TaskName
	if taskName == "" {
		taskName = "dart_go_bridge"
	}

	model := llm.BuildChain(llm.ModelChainConfig{
		Context:  context.Background(),
		TaskName: taskName,
		Criteria: buildCriteria(),
	})
	if model == nil {
		return responseCString(jsonResponse{Ok: false, Error: "no model chain available (check API keys)"})
	}

	call := unillm.Call{
		Prompt:          prompt,
		MaxOutputTokens: req.MaxOutputTokens,
		Temperature:     req.Temperature,
		TopP:            req.TopP,
		TopK:            req.TopK,
	}

	stream, err := model.Stream(context.Background(), call)
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}

	state := &streamState{
		ch:   make(chan unillm.StreamPart, 16),
		done: make(chan struct{}),
	}

	go func() {
		defer close(state.ch)
		stream(func(part unillm.StreamPart) bool {
			state.ch <- part
			return true
		})
		close(state.done)
	}()

	handle := nextStreamHandle(state)
	return responseCString(jsonResponse{Ok: true, Handle: handle})
}

//export LLMStreamNextJSON
func LLMStreamNextJSON(handle C.uint64_t) *C.char {
	state, err := getStreamHandle(uint64(handle))
	if err != nil {
		return responseCString(jsonResponse{Ok: false, Error: err.Error()})
	}

	for {
		select {
		case part, ok := <-state.ch:
			if !ok {
				return responseCString(jsonResponse{Ok: true, Data: map[string]any{"done": true}})
			}
			if part.Error != nil {
				return responseCString(jsonResponse{Ok: false, Error: part.Error.Error()})
			}
			if part.Type != unillm.StreamPartTypeTextDelta {
				continue
			}
			return responseCString(jsonResponse{Ok: true, Data: map[string]any{"done": false, "text": part.Delta}})
		case <-state.done:
			return responseCString(jsonResponse{Ok: true, Data: map[string]any{"done": true}})
		}
	}
}

//export LLMStreamFree
func LLMStreamFree(handle C.uint64_t) {
	deleteStreamHandle(uint64(handle))
}
