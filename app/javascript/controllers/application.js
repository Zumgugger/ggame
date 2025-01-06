 import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["output"]

  connect() {
    console.log("Stimulus controller connected")
  }

  updateOutput() {
    this.outputTarget.textContent = "Hello, Stimulus!"
  }
}
