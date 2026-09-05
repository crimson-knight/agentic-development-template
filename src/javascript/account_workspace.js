const menuToggle = document.querySelector('[data-menu-toggle]');
const menu = document.getElementById('account-menu');
const narrow = matchMedia('(max-width: 760px)');
function closeMenu() {
  if (!menuToggle || !menu) return;
  menuToggle.setAttribute('aria-expanded', 'false');
  menu.hidden = narrow.matches;
}
closeMenu();
narrow.addEventListener('change', closeMenu);
menuToggle?.addEventListener('click', () => {
  menu.hidden = !menu.hidden;
  menuToggle.setAttribute('aria-expanded', String(!menu.hidden));
});
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && menuToggle?.getAttribute('aria-expanded') === 'true') {
    closeMenu(); menuToggle.focus();
  }
});
for (const form of document.querySelectorAll('[data-account-form]')) {
  const button = form.querySelector('button[type="submit"]');
  const originalLabel = button.textContent;
  function validate() {
    if (form.dataset.busy === 'true') return;
    let valid = form.checkValidity();
    if (form.hasAttribute('data-password-form')) {
      const password = form.elements.password.value;
      const confirmation = form.elements.password_confirmation.value;
      const rules = {
        length: Array.from(password).length >= 8,
        bytes: password.length > 0 && new TextEncoder().encode(password).length <= 71,
        match: password.length > 0 && password === confirmation,
      };
      for (const [name, satisfied] of Object.entries(rules)) {
        form.querySelector(`[data-rule="${name}"]`).dataset.valid = String(satisfied);
      }
      valid = valid && Object.values(rules).every(Boolean);
    }
    button.disabled = !valid;
  }
  form.addEventListener('input', validate);
  form.addEventListener('change', validate);
  form.addEventListener('submit', (event) => {
    if (form.dataset.busy === 'true' || button.disabled || !form.reportValidity()) { event.preventDefault(); return; }
    form.dataset.busy = 'true'; form.setAttribute('aria-busy', 'true');
    button.disabled = true; button.textContent = button.dataset.busyLabel || 'Saving…';
  });
  addEventListener('pageshow', () => {
    delete form.dataset.busy; form.removeAttribute('aria-busy'); button.textContent = originalLabel; validate();
  });
  validate();
}
