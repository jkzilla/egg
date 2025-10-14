package signal

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
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

// GetQRCode retrieves the QR code link from Signal CLI REST API
func GetQRCode() (string, error) {
	signalAPIURL := os.Getenv("SIGNAL_API_URL")
	if signalAPIURL == "" {
		return "", fmt.Errorf("SIGNAL_API_URL not set")
	}

	resp, err := http.Get(signalAPIURL + "/v1/qrcodelink?device_name=haileys-garden")
	if err != nil {
		return "", fmt.Errorf("failed to get QR code: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Signal API returned status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	return string(body), nil
}

// GetQRCodeImage retrieves the QR code as PNG image from Signal CLI REST API
func GetQRCodeImage() ([]byte, error) {
	qrLink, err := GetQRCode()
	if err != nil {
		return nil, err
	}

	// The QR link is the data we need to encode as a QR code image
	// Signal CLI REST API returns the link, we need to generate the PNG
	// For now, return the link as text
	return []byte(qrLink), nil
}
