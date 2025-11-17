/**
 * Team A Service
 * Example package for demonstrating JFrog team isolation
 */

function greet(name) {
  return `Hello from Team A Service, ${name}!`;
}

function getTeamInfo() {
  return {
    team: 'team-a',
    service: 'my-service',
    version: '1.0.0',
    description: 'This package is only accessible to Team A members'
  };
}

module.exports = {
  greet,
  getTeamInfo
};
