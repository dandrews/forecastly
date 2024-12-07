// Weather form controller
export default class WeatherController {
  static validateForm() {
    const addressInput = document.getElementById("address-input");
    const submitButton = document.getElementById("submit-weather");

    if (addressInput.value.trim().length > 0) {
      submitButton.disabled = false;
    } else {
      submitButton.disabled = true;
    }
  }
}

// Add this at the end of the file
document.addEventListener("DOMContentLoaded", () => {
  WeatherController.validateForm();
});
