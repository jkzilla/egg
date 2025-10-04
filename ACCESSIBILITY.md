# Accessibility Statement

Hailey's Garden is committed to ensuring digital accessibility for people with disabilities. We are continually improving the user experience for everyone and applying the relevant accessibility standards.

## Conformance Status

This application strives to conform to the [Web Content Accessibility Guidelines (WCAG) 2.1](https://www.w3.org/WAI/WCAG21/quickref/) Level AA standards. These guidelines explain how to make web content more accessible for people with disabilities.

## Accessibility Features

### Keyboard Navigation
- **Full keyboard support**: All interactive elements can be accessed and operated using only a keyboard
- **Tab order**: Logical tab order through all interactive elements
- **Focus indicators**: Visible focus indicators on all interactive elements
- **Escape key**: Close modals and overlays with the Escape key

### Screen Reader Support
- **ARIA labels**: Comprehensive ARIA labels on all interactive elements
- **Semantic HTML**: Proper use of semantic HTML5 elements (header, main, nav, button, etc.)
- **Alt text**: Descriptive alternative text for all meaningful images
- **Live regions**: ARIA live regions for dynamic content updates (cart notifications, purchase confirmations)
- **Form labels**: All form inputs have associated labels

### Visual Design
- **Color contrast**: Minimum 4.5:1 contrast ratio for normal text, 3:1 for large text
- **Text sizing**: Responsive text that scales with browser zoom (up to 200%)
- **Focus indicators**: Clear visual focus indicators for keyboard navigation
- **No color-only information**: Information is not conveyed by color alone

### Responsive Design
- **Mobile accessible**: Fully functional on mobile devices with touch targets at least 44x44 pixels
- **Viewport scaling**: Supports browser zoom and text-only zoom
- **Flexible layouts**: Content reflows appropriately at different screen sizes

## Implemented Accessibility Standards

### WCAG 2.1 Level AA Compliance

#### Perceivable
- ✅ **1.1.1 Non-text Content**: All images have alt text
- ✅ **1.3.1 Info and Relationships**: Semantic HTML and ARIA labels
- ✅ **1.3.2 Meaningful Sequence**: Logical reading order
- ✅ **1.4.3 Contrast (Minimum)**: 4.5:1 contrast ratio for text
- ✅ **1.4.4 Resize Text**: Text can be resized up to 200%
- ✅ **1.4.10 Reflow**: Content reflows without horizontal scrolling
- ✅ **1.4.11 Non-text Contrast**: 3:1 contrast for UI components

#### Operable
- ✅ **2.1.1 Keyboard**: All functionality available via keyboard
- ✅ **2.1.2 No Keyboard Trap**: No keyboard traps
- ✅ **2.4.3 Focus Order**: Logical focus order
- ✅ **2.4.7 Focus Visible**: Visible focus indicators
- ✅ **2.5.5 Target Size**: Touch targets at least 44x44 pixels

#### Understandable
- ✅ **3.1.1 Language of Page**: HTML lang attribute set
- ✅ **3.2.1 On Focus**: No context changes on focus
- ✅ **3.2.2 On Input**: No unexpected context changes
- ✅ **3.3.1 Error Identification**: Clear error messages
- ✅ **3.3.2 Labels or Instructions**: All inputs have labels

#### Robust
- ✅ **4.1.2 Name, Role, Value**: Proper ARIA attributes
- ✅ **4.1.3 Status Messages**: ARIA live regions for status updates

## Component-Specific Accessibility

### Shopping Cart
- **ARIA labels**: Cart button has descriptive label with item count
- **Modal accessibility**: Cart sidebar is properly announced to screen readers
- **Focus management**: Focus is trapped within the cart when open
- **Keyboard navigation**: Can be closed with Escape key or close button

### Product Cards
- **Semantic structure**: Proper heading hierarchy
- **Button labels**: Clear, descriptive button text
- **Input labels**: Quantity inputs have associated labels
- **Disabled states**: Disabled buttons are properly announced

### Forms and Inputs
- **Labels**: All inputs have visible and programmatic labels
- **Error handling**: Errors are announced to screen readers
- **Required fields**: Required fields are marked and announced
- **Input constraints**: Min/max values are enforced and announced

## Testing

### Automated Testing
We use automated accessibility testing tools:
- **axe-core**: Integrated into development workflow
- **Lighthouse**: Regular accessibility audits
- **ESLint jsx-a11y**: Linting for accessibility issues

### Manual Testing
- **Keyboard navigation**: Regular testing with keyboard-only navigation
- **Screen readers**: Testing with NVDA (Windows), JAWS (Windows), and VoiceOver (macOS/iOS)
- **Browser zoom**: Testing at 200% zoom level
- **Color blindness**: Testing with color blindness simulators

### Assistive Technologies Tested
- **Screen readers**: NVDA, JAWS, VoiceOver
- **Browsers**: Chrome, Firefox, Safari, Edge (latest versions)
- **Mobile**: iOS VoiceOver, Android TalkBack

## Known Issues and Limitations

We are actively working to address the following:
- [ ] High contrast mode support could be improved
- [ ] Some third-party dependencies may have accessibility issues
- [ ] Additional keyboard shortcuts for power users

## Feedback

We welcome feedback on the accessibility of Hailey's Garden. If you encounter any accessibility barriers, please let us know:

- **GitHub Issues**: [https://github.com/jkzilla/egg/issues](https://github.com/jkzilla/egg/issues)
- **Email**: accessibility@haileysgarden.com

Please provide:
1. The page or feature where you encountered the issue
2. The assistive technology you were using (if applicable)
3. A description of the problem
4. Any suggestions for improvement

## Continuous Improvement

We are committed to ongoing accessibility improvements:
- Regular accessibility audits
- User testing with people with disabilities
- Staying current with WCAG guidelines and best practices
- Training development team on accessibility standards

## Resources

- [Web Content Accessibility Guidelines (WCAG) 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [WebAIM](https://webaim.org/)
- [A11y Project](https://www.a11yproject.com/)

## Last Updated

This accessibility statement was last updated on October 4, 2025.
