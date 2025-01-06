import { pplication } from "stimulus";
import { definitionsFromContext } from "stimulus";
//import { Turbo } from "@hotwired/turbo-rails";  // If you're using Turbo

// Initialize Stimulus application
Rails.start();

// Create a new Stimulus application
const application = Application.start();


// Expose the Stimulus app to the global window for debugging (optional)
window.Stimulus = application;

export { application };

