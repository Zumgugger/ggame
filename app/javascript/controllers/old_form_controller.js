import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["action", "minepoints", "target", "targetGroup"];

  change() {
    const actionText = this.actionTarget.value;  // Get the selected value
    console.log('Selected Action:', actionText);  // Debugging: see the selected value

    // Hide all fields initially
    this.hideAllFields();

    // Show appropriate field based on selected action
    switch (actionText) {
      case "hat Mine gesetzt":
        this.showFields([this.minepointsTarget, this.targetTarget]);
        break;
      case "hat Posten geholt":
        this.showFields([this.targetTarget]);
        break;
      case "hat Gruppe fotografiert":
      case "hat spioniert":
      case "hat sondiert":
        this.showFields([this.targetGroupTarget]);
        break;
      case "hat Foto bemerkt":
        this.showFields([this.targetGroupTarget]);
        break;
      case "hat Kopfgeld gesetzt":
        this.showFields([this.minepointsTarget, this.targetGroupTarget]);
        break;
      case "hat Mine entschärft":
        this.showFields([this.targetTarget]);
        break;
      case "Spionageabwehr":
        this.hideAllFields();  // Hide all fields in this case
        break;import { Controller } from "stimulus";

        export default class extends Controller {
          static targets = ["action", "minepoints", "target", "targetGroup"];
        
          connect() {
            console.log("Form Controller Loaded");
          }
        
          change() {
            const actionText = this.actionTarget.value;
            console.log('Selected Action:', actionText);
        
            this.hideAllFields();
        
            switch (actionText) {
              case "hat Mine gesetzt":
                this.showFields([this.minepointsTarget, this.targetTarget]);
                break;
              case "hat Posten geholt":
                this.showFields([this.targetTarget]);
                break;
              case "hat Gruppe fotografiert":
              case "hat spioniert":
              case "hat sondiert":
                this.showFields([this.targetGroupTarget]);
                break;
              case "hat Foto bemerkt":
                this.showFields([this.targetGroupTarget]);
                break;
              case "hat Kopfgeld gesetzt":
                this.showFields([this.minepointsTarget, this.targetGroupTarget]);
                break;
              case "hat Mine entschärft":
                this.showFields([this.targetTarget]);
                break;
              case "Spionageabwehr":
                this.hideAllFields();
                break;
              default:
                console.log('Action not recognized');
            }
          }
        
          showFields(targets) {
            targets.forEach(target => {
              target.style.display = "block";
            });
          }
        
          hideAllFields() {
            [this.minepointsTarget, this.targetTarget, this.targetGroupTarget].forEach(target => {
              target.style.display = "none";
            });
          }
        }
        
      default:
        console.log('Action not recognized');  // Debugging: log when action is not recognized
    }
  }

  // Helper method to show the fields
  showFields(targets) {
    targets.forEach(target => {
      target.style.display = "block";
    });
  }

  // Helper method to hide all fields
  hideAllFields() {
    [this.minepointsTarget, this.targetTarget, this.targetGroupTarget].forEach(target => {
      target.style.display = "none";
    });
  }
}
