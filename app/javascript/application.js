// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import WeatherController from "./controllers/weather_controller";

// Make controller available globally
window.WeatherController = WeatherController;
