# Contributing to Hailey's Garden

Thank you for your interest in contributing to Hailey's Garden! We welcome contributions from the community and are grateful for your support.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Accessibility](#accessibility)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@haileysgarden.com.

## Getting Started

### Prerequisites

- **Go**: 1.22 or higher
- **Node.js**: 20 or higher
- **npm**: 10 or higher
- **Git**: Latest version

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/egg.git
   cd egg
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/jkzilla/egg.git
   ```

### Install Dependencies

**Backend:**
```bash
go mod download
```

**Frontend:**
```bash
cd frontend
npm install
cd ..
```

### Run Development Environment

**Terminal 1 - Backend:**
```bash
go run .
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

Visit `http://localhost:5173` to see the application.

## How to Contribute

### Types of Contributions

We welcome many types of contributions:

- 🐛 **Bug fixes**
- ✨ **New features**
- 📝 **Documentation improvements**
- 🎨 **UI/UX enhancements**
- ♿ **Accessibility improvements**
- 🧪 **Tests**
- 🌐 **Translations**
- 🔧 **DevOps and tooling**

### First-Time Contributors

Look for issues labeled `good first issue` or `help wanted`. These are great starting points for new contributors.

## Development Workflow

### 1. Create a Branch

Create a feature branch from `main`:

```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or changes
- `chore/` - Maintenance tasks

### 2. Make Your Changes

- Write clean, readable code
- Follow existing code style
- Add tests for new functionality
- Update documentation as needed
- Ensure accessibility standards are met

### 3. Test Your Changes

**Backend tests:**
```bash
go test ./...
```

**Frontend tests:**
```bash
cd frontend
npm run lint
npm run test:e2e
```

**Manual testing:**
- Test in multiple browsers (Chrome, Firefox, Safari)
- Test with keyboard navigation
- Test with a screen reader if possible
- Test at different screen sizes

### 4. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git add .
git commit -m "feat: add new egg variety filter

- Add dropdown filter for egg types
- Update GraphQL query to support filtering
- Add tests for filter functionality"
```

**Commit message format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Maintenance tasks

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Coding Standards

### Go (Backend)

- Follow [Effective Go](https://golang.org/doc/effective_go.html) guidelines
- Use `gofmt` for formatting
- Run `go vet` to catch common mistakes
- Add comments for exported functions and types
- Keep functions small and focused

**Example:**
```go
// GetEggByID retrieves an egg by its unique identifier.
// Returns an error if the egg is not found.
func GetEggByID(id string) (*Egg, error) {
    // Implementation
}
```

### TypeScript/React (Frontend)

- Use TypeScript for type safety
- Follow React best practices and hooks guidelines
- Use functional components
- Keep components small and reusable
- Use meaningful variable and function names

**Example:**
```typescript
interface EggCardProps {
  egg: Egg
  onAddToCart: (egg: Egg, quantity: number) => void
}

export default function EggCard({ egg, onAddToCart }: EggCardProps) {
  // Implementation
}
```

### CSS/Tailwind

- Use Tailwind utility classes
- Keep custom CSS minimal
- Ensure responsive design
- Maintain color contrast ratios (WCAG AA)

## Testing

### Backend Testing

Write unit tests for all new functionality:

```go
func TestGetEggByID(t *testing.T) {
    egg, err := GetEggByID("1")
    if err != nil {
        t.Errorf("Expected no error, got %v", err)
    }
    if egg.ID != "1" {
        t.Errorf("Expected ID 1, got %s", egg.ID)
    }
}
```

### Frontend Testing

Write E2E tests using Playwright:

```typescript
test('should add item to cart', async ({ page }) => {
  await page.goto('http://localhost:5173')
  await page.click('button:has-text("Add to Cart")')
  await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1')
})
```

### Test Coverage

- Aim for at least 80% code coverage
- Test edge cases and error conditions
- Test accessibility with automated tools

## Accessibility

All contributions must meet accessibility standards:

### Requirements

- ✅ All interactive elements must be keyboard accessible
- ✅ All images must have alt text
- ✅ Color contrast must meet WCAG AA standards (4.5:1)
- ✅ All form inputs must have labels
- ✅ ARIA labels must be added where appropriate
- ✅ Focus indicators must be visible

### Testing Accessibility

1. **Keyboard navigation**: Tab through all interactive elements
2. **Screen reader**: Test with VoiceOver (Mac) or NVDA (Windows)
3. **Automated tools**: Run Lighthouse accessibility audit
4. **Color contrast**: Use browser DevTools to check contrast

### Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WAI-ARIA Practices](https://www.w3.org/WAI/ARIA/apg/)
- [WebAIM](https://webaim.org/)

## Pull Request Process

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] Accessibility requirements met
- [ ] No secrets or sensitive data committed
- [ ] Commit messages are clear and descriptive

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Accessibility improvement

## Testing
- [ ] Backend tests pass
- [ ] Frontend tests pass
- [ ] Manual testing completed
- [ ] Accessibility tested

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
```

### Review Process

1. **Automated checks**: CircleCI runs tests and security scans
2. **Code review**: Maintainers review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged

### After Your PR is Merged

- Delete your feature branch
- Update your local repository:
  ```bash
  git checkout main
  git pull upstream main
  ```

## Reporting Bugs

### Before Reporting

1. Check if the bug has already been reported
2. Ensure you're using the latest version
3. Try to reproduce the bug

### Bug Report Template

```markdown
**Describe the bug**
A clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
Add screenshots if applicable

**Environment:**
- OS: [e.g., macOS 14.0]
- Browser: [e.g., Chrome 120]
- Version: [e.g., 1.0.0]

**Additional context**
Any other relevant information
```

## Suggesting Enhancements

We welcome feature suggestions! Please:

1. Check if the feature has already been suggested
2. Provide a clear use case
3. Explain how it benefits users
4. Consider implementation complexity

### Enhancement Template

```markdown
**Feature Description**
Clear description of the proposed feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should this work?

**Alternatives Considered**
Other approaches you've thought about

**Additional Context**
Mockups, examples, or references
```

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Pull Requests**: Code contributions

### Getting Help

- Check the [README](README.md) for setup instructions
- Review existing issues and discussions
- Ask questions in GitHub Discussions
- Be patient and respectful

## Recognition

Contributors are recognized in several ways:

- Listed in GitHub contributors
- Mentioned in release notes for significant contributions
- Community recognition for ongoing contributions

## License

By contributing to Hailey's Garden, you agree that your contributions will be licensed under the MIT License.

## Questions?

If you have questions about contributing, please:
- Open a GitHub Discussion
- Review existing documentation
- Contact the maintainers

Thank you for contributing to Hailey's Garden! 🥚 🌱
