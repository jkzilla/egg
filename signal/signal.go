package signal

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

// SendMessage sends a message using Signal CLI REST API
func SendMessage(to, message string) error {
	signalAPIURL := os.Getenv("SIGNAL_API_URL")
	signalNumber := os.Getenv("SIGNAL_NUMBER")

	if signalAPIURL == "" || signalNumber == "" {
		return fmt.Errorf("Signal configuration not set")
	}

	payload := map[string]interface{}{
		"message":    message,
		"number":     signalNumber,
		"recipients": []string{to},
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}

	req, err := http.NewRequest("POST", signalAPIURL+"/v2/send", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send message: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return fmt.Errorf("Signal API returned status: %d", resp.StatusCode)
	}

	return nil
}
