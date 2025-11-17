# @shared/common-utils

Shared utilities for Hailey's Garden projects (web-dev and ios teams).

## Installation

```bash
npm install @shared/common-utils
```

## Usage

### String Utilities

```typescript
import { capitalize, toKebabCase, toCamelCase, truncate } from '@shared/common-utils';

capitalize('hello'); // 'Hello'
toKebabCase('HelloWorld'); // 'hello-world'
toCamelCase('hello-world'); // 'helloWorld'
truncate('Long text here', 10); // 'Long te...'
```

### Date Utilities

```typescript
import { isPast, isFuture, daysDifference, addDays } from '@shared/common-utils';

isPast(new Date('2020-01-01')); // true
isFuture(new Date('2030-01-01')); // true
daysDifference(new Date('2024-01-01'), new Date('2024-01-10')); // 9
addDays(new Date(), 7); // Date 7 days from now
```

### Validation

```typescript
import { isEmpty, isValidEmail, isValidUrl, isValidUUID } from '@shared/common-utils';

isEmpty(''); // true
isValidEmail('test@example.com'); // true
isValidUrl('https://example.com'); // true
isValidUUID('123e4567-e89b-12d3-a456-426614174000'); // true
```

### Logger

```typescript
import { createLogger } from '@shared/common-utils';

const logger = createLogger('MyService');
logger.info('Application started');
logger.error('Something went wrong', error);
```

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Test
npm test

# Publish to JFrog
npm publish --registry https://your-jfrog-url/artifactory/api/npm/npm-dev-local/
```

## License

MIT
