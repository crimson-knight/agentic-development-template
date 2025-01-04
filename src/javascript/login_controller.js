import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["email", "password", "submitButton"];

  connect() {
    this.toggleSubmitButton();
    console.log("LoginController connected");
  }

  toggleSubmitButton() {
    const isEmailValid = this.emailTarget.validity.valid;
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
      const response = await fetch("/login", {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('input[name="_csrf"]').content
        }
      });

      console.log("Response: ", response);

      if (response.ok) {
        const data = await response.json();
        window.location.href = data.redirect_url;
      }
    } catch (error) {
      console.error("Error submitting form:", error);
    }
  }
}
