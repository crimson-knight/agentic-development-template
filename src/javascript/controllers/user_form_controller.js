import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatarInput", "avatarPreview", "resumeInput"]

  connect() {
    console.log("User form controller connected")
  }

  previewAvatar(event) {
    const file = event.target.files[0]

    if (!file) {
      this.clearPreview()
      return
    }

    // Validate file size (5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert("File size must be less than 5MB")
      this.avatarInputTarget.value = ""
      this.clearPreview()
      return
    }

    // Validate file type
    const allowedTypes = ["image/jpeg", "image/png", "image/webp"]
    if (!allowedTypes.includes(file.type)) {
      alert("Only JPEG, PNG, and WebP images are allowed")
      this.avatarInputTarget.value = ""
      this.clearPreview()
      return
    }

    // Create preview
    const reader = new FileReader()
    reader.onload = (e) => {
      this.avatarPreviewTarget.innerHTML = `
        <img src="${e.target.result}" alt="Avatar preview" style="max-width: 200px; margin-top: 10px;">
      `
    }
    reader.readAsDataURL(file)
  }

  clearPreview() {
    if (this.hasAvatarPreviewTarget) {
      this.avatarPreviewTarget.innerHTML = ""
    }
  }

  disconnect() {
    console.log("User form controller disconnected")
  }
}
