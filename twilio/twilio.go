package twilio

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
)

// SendSMS sends an SMS message using Twilio API
func SendSMS(to, message string) error {
	accountSID := os.Getenv("TWILIO_ACCOUNT_SID")
	authToken := os.Getenv("TWILIO_AUTH_TOKEN")
	fromNumber := os.Getenv("TWILIO_PHONE_NUMBER")

	if accountSID == "" || authToken == "" || fromNumber == "" {
		return fmt.Errorf("Twilio credentials not configured")
	}

	urlStr := fmt.Sprintf("https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json", accountSID)

	msgData := url.Values{}
	msgData.Set("To", to)
	msgData.Set("From", fromNumber)
	msgData.Set("Body", message)

	client := &http.Client{}
	req, err := http.NewRequest("POST", urlStr, strings.NewReader(msgData.Encode()))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.SetBasicAuth(accountSID, authToken)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send SMS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		return fmt.Errorf("twilio API returned status: %d", resp.StatusCode)
	}

	return nil
}
