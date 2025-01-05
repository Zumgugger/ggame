import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import { Turbo } from "@hotwired/turbo-rails"

// Start Stimulus application
const application = Application.start()

// Load all controllers from the controllers directory
const context = require.context("controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

// Make the application available for debugging in the global scope (optional)
window.Stimulus = application

export { application }
