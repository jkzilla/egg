# @team-a/my-service

Team A example service for JFrog Artifactory demo.

## Installation

```bash
npm install @team-a/my-service
```

## Usage

```javascript
const teamAService = require('@team-a/my-service');

// Greet someone
console.log(teamAService.greet('Developer'));
// Output: Hello from Team A Service, Developer!

// Get team info
console.log(teamAService.getTeamInfo());
// Output: { team: 'team-a', service: 'my-service', version: '1.0.0', ... }
```

## Access Control

This package is only accessible to:
- ✅ Team A members (user-webdev1, user-webdev2)
- ✅ Managers (johanna@haileysgarden.com)
- ❌ Team B members (user-ios1, user-ios2) - will get 403 Forbidden

## Demo

This package demonstrates JFrog's Repository Path Permissions (RPP) for team isolation.
