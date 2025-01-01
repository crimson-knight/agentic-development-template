import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["username", "password", "submitButton"];

  connect() {
    this.toggleSubmitButton();
    console.log("LoginController connected");
  }

  toggleSubmitButton() {
    const isEmailValid = this.usernameTarget.validity.valid;
    const isPasswordValid = this.passwordTarget.value.length > 6;
    this.submitButtonTarget.disabled = !(isEmailValid && isPasswordValid);
  }

  handleInput() {
    this.toggleSubmitButton();
  }

  async handleSubmit(event) {
    event.preventDefault();
    const formData = new FormData(this.element);

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      });

      if (response.ok) {
        const data = await response.json();
        window.location.href = data.redirect_url;
      } else {
        window.location.reload();
      }
    } catch (error) {
      console.error("Error submitting form:", error);
      window.location.reload();
    }
  }
}
