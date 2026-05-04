describe('Login Flow', () => {
  it('should navigate to the login page and show the login form', () => {
    // Cypress requires uncaught exception handler just in case third-party scripts fail
    Cypress.on('uncaught:exception', () => {
      return false;
    });

    cy.visit('/login');

    // Check if sign in related text or email input is visible
    cy.get('input[type="email"], input[name="email"]').should('be.visible');
    cy.get('input[type="password"], input[name="password"]').should(
      'be.visible'
    );

    cy.get('input[type="email"], input[name="email"]').type('test@example.com');
    cy.get('input[type="password"], input[name="password"]').type(
      'password123'
    );

    // Button should be visible
    cy.get('button[type="submit"]').should('be.visible');
  });
});
