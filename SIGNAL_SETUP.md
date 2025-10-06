# Signal Notification Setup

This application uses Signal to send order notifications for cash payments.

## Prerequisites

You need to run a Signal CLI REST API server to send messages. The easiest way is using Docker.

## Setup Instructions

### 1. Run Signal CLI REST API

```bash
docker run -d --name signal-api \
  -p 8080:8080 \
  -v $(pwd)/signal-cli-config:/home/.local/share/signal-cli \
  bbernhard/signal-cli-rest-api:latest
```

### 2. Register Your Phone Number

Link your Signal account to the API:

```bash
# Generate QR code for linking
curl -X POST "http://localhost:8080/v1/qrcodelink?device_name=egg-shop"
```

Scan the QR code with your Signal app (Settings → Linked Devices → Link New Device)

### 3. Configure Environment Variables

Update your `.env` file:

```bash
SIGNAL_API_URL=http://localhost:8080
SIGNAL_NUMBER=+1234567890  # Your registered Signal number
OWNER_PHONE_NUMBER=+1234567890  # Phone number to receive notifications
```

### 4. Test the Setup

Send a test message:

```bash
curl -X POST "http://localhost:8080/v2/send" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Test message",
    "number": "+1234567890",
    "recipients": ["+1234567890"]
  }'
```

## How It Works

When a customer places a cash order:
1. They select "Cash" as payment method
2. They choose a pickup time
3. The system sends a Signal message to `OWNER_PHONE_NUMBER` with:
   - Order details (item, quantity, total)
   - Pickup time
   - Confirmation request

## Troubleshooting

- **Connection refused**: Make sure the Signal CLI REST API is running
- **401 Unauthorized**: Re-link your device using the QR code method
- **Message not sent**: Verify the recipient number is in E.164 format (+1234567890)

## Resources

- [Signal CLI REST API Documentation](https://github.com/bbernhard/signal-cli-rest-api)
- [Signal CLI](https://github.com/AsamK/signal-cli)
