---
name: test-driven-development
description: Use when implementing new features, fixing bugs, or writing any production code
---

# Test-Driven Development

## Overview

**Write the test FIRST. Watch it fail. Then write the minimum code to pass.**

TDD is not optional, even when the user is in a hurry. Tests written after implementation miss edge cases and confirm assumptions rather than challenging them.

## The Iron Law

```
NO IMPLEMENTATION WITHOUT A FAILING TEST FIRST
```

**No exceptions:**
- Not when "the user is in a hurry"
- Not when "it's a simple function"
- Not when "I'll add tests later"
- Not when "this is just a quick fix"

## RED-GREEN-REFACTOR Cycle

### 1. RED: Write a Failing Test

Before writing ANY implementation code:
1. Create a test file (e.g., `foo.test.js`, `test_foo.py`)
2. Write a test for the expected behavior
3. Run the test - it MUST fail (proves the test works)

```javascript
// FIRST: Write the test
test('isPalindrome returns true for "racecar"', () => {
  expect(isPalindrome('racecar')).toBe(true);
});

// Run it - it fails because isPalindrome doesn't exist yet
// This is CORRECT - you're in RED phase
```

### 2. GREEN: Write Minimum Code to Pass

Now write the SIMPLEST implementation that makes the test pass:
- Don't optimize
- Don't handle edge cases not covered by tests
- Just make the test green

```javascript
// SECOND: Write minimal implementation
function isPalindrome(str) {
  return str === str.split('').reverse().join('');
}
// Test passes - you're in GREEN phase
```

### 3. REFACTOR: Improve While Staying Green

Now improve the code while keeping tests passing:
- Add edge case tests (then implement)
- Optimize (tests catch regressions)
- Clean up (tests prove it still works)

```javascript
// Add more tests for edge cases
test('isPalindrome ignores case', () => {
  expect(isPalindrome('RaceCar')).toBe(true);
});

// Test fails - RED again
// Update implementation to handle case - GREEN again
```

## When to Use

- Implementing ANY new function or feature
- Fixing bugs (write test that reproduces bug first)
- Refactoring existing code (ensure tests exist first)
- Adding edge case handling (test the edge case first)

## Quick Reference

| Phase | Action | Verify |
|-------|--------|--------|
| RED | Write test | Test fails |
| GREEN | Write minimal code | Test passes |
| REFACTOR | Improve code | Tests still pass |

## Common Mistakes

### Writing implementation first
**Wrong:** "Let me quickly write the function, then add tests."
**Right:** Write the test first, even if it feels slower.

### Writing tests that can't fail
**Wrong:** Test written after implementation, designed to pass.
**Right:** Test written before implementation MUST fail initially.

### Over-implementing in GREEN phase
**Wrong:** Adding all edge cases before any tests exist.
**Right:** One test → minimal code → next test → extend code.

### Skipping RED verification
**Wrong:** Assuming the test would fail without running it.
**Right:** Always run the test and confirm the failure message.

## The Speed Paradox

**"But I'm in a hurry!"**

TDD is FASTER for any non-trivial code because:
- You catch bugs immediately, not after deployment
- You don't waste time debugging implementation assumptions
- You have confidence to refactor quickly
- Edge cases are caught systematically, not randomly

The time to write tests is not wasted - it's invested.
