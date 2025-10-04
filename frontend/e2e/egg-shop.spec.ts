import { test, expect } from '@playwright/test';

test.describe('Egg Shop E2E Tests', () => {

  // Test 1: Page loads and displays eggs
  test('should load the page and display egg products', async ({ page }) => {
    await page.goto('/');

    // Check header is visible
    await expect(page.getByRole('heading', { name: /Hailey's Garden/i })).toBeVisible();

    // Check that egg cards are displayed
    await expect(page.locator('.grid')).toBeVisible();

    // Verify at least one egg product is shown
    await expect(page.getByText(/Brown Chicken Egg|White Chicken Egg|Duck Egg|Quail Egg/)).toBeVisible();

    // Check that prices are displayed
    await expect(page.getByText(/\$/)).toBeVisible();
  });

  // Test 2: Add item to cart
  test('should add an item to the cart', async ({ page }) => {
    await page.goto('/');

    // Wait for eggs to load
    await page.waitForSelector('text=Brown Chicken Egg', { timeout: 10000 });

    // Find the first "Add to Cart" button and click it
    const addToCartButton = page.getByRole('button', { name: 'Add to Cart' }).first();
    await addToCartButton.click();

    // Verify cart badge shows 1 item
    await expect(page.locator('span').filter({ hasText: '1' }).first()).toBeVisible();
  });

  // Test 3: Open cart and view items
  test('should open shopping cart and display items', async ({ page }) => {
    await page.goto('/');

    // Wait for eggs to load
    await page.waitForSelector('text=Brown Chicken Egg', { timeout: 10000 });

    // Add item to cart
    await page.getByRole('button', { name: 'Add to Cart' }).first().click();

    // Wait a moment for cart to update
    await page.waitForTimeout(500);

    // Click cart button (the shopping cart icon button)
    await page.locator('button').filter({ has: page.locator('svg') }).first().click();

    // Verify cart sidebar is open
    await expect(page.getByRole('heading', { name: 'Shopping Cart' })).toBeVisible();

    // Verify item is in cart
    await expect(page.getByText(/Brown Chicken Egg|White Chicken Egg|Duck Egg|Quail Egg/).first()).toBeVisible();

    // Verify total price is shown
    await expect(page.getByText(/Total:/)).toBeVisible();
  });

  // Test 4: Update quantity in cart
  test('should update item quantity in cart', async ({ page }) => {
    await page.goto('/');

    // Wait for eggs to load
    await page.waitForSelector('text=Brown Chicken Egg', { timeout: 10000 });

    // Add item to cart
    await page.getByRole('button', { name: 'Add to Cart' }).first().click();

    // Open cart
    await page.locator('button').filter({ has: page.locator('svg') }).first().click();

    // Find quantity input in cart
    const quantityInput = page.locator('input[type="number"]').last();

    // Clear and set new quantity
    await quantityInput.clear();
    await quantityInput.fill('3');

    // Verify the input value changed
    await expect(quantityInput).toHaveValue('3');
  });

  // Test 5: Clear cart
  test('should clear all items from cart', async ({ page }) => {
    await page.goto('/');

    // Wait for eggs to load
    await page.waitForSelector('text=Brown Chicken Egg', { timeout: 10000 });

    // Add multiple items to cart
    const addButtons = page.getByRole('button', { name: 'Add to Cart' });
    await addButtons.first().click();
    await page.waitForTimeout(300);
    await addButtons.nth(1).click();

    // Open cart
    await page.locator('button').filter({ has: page.locator('svg') }).first().click();

    // Click clear cart button
    await page.getByRole('button', { name: 'Clear Cart' }).click();

    // Verify cart is empty
    await expect(page.getByText('Your cart is empty')).toBeVisible();
  });
});
