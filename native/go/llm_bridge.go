package main

// #include <stdint.h>
// #include <stdlib.h>
import "C"

import (
	"context"
	"encoding/json"
	"errors"

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

	criteria := openrouter.ModelSelectionCriteria{
		RequireReasoning:   false,
		RequireAttachments: false,
		MinContextWindow:   4096,
	}

	model := llm.BuildChain(llm.ModelChainConfig{
		Context:  context.Background(),
		TaskName: taskName,
		Criteria: criteria,
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
