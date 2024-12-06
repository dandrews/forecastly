# Handles weather-related requests and displays weather information for given addresses
#
# @example Fetch weather for a US address
#   get '/weather?address=New York, NY 10001'
#
# @example Fetch weather for an international address
#   get '/weather?address=Paris, France'
#
# @decomposition
#   - WeatherController: Main controller handling weather data requests
#   - Address Validation: Validates presence of address parameter
#   - Weather Service Integration: Delegates weather fetching to Weather::Client
#   - Error Handling: Manages and displays fetch failures
#
# @design_patterns
#   - MVC Pattern: Follows Rails controller conventions for handling weather requests
#   - Service Object Pattern: Delegates weather fetching to dedicated Weather::Client service
#   - Flash Message Pattern: Uses flash messages for error communication
class WeatherController < ApplicationController
  # GET /weather
  # Fetches and displays weather data for a specified address
  #
  # @option params [String] :address The address to fetch weather data for
  # @return [void]
  def index
    @address = params[:address]

    if @address.present?
      Rails.logger.debug("Attempting to fetch weather for: #{@address}")
      # Calls the Weather::Client service to retrieve weather data
      @weather_data = Weather::Client.get_weather(@address)
      Rails.logger.debug("Weather data returned: #{@weather_data.inspect}")

      # Handle case where weather data couldn't be retrieved
      if @weather_data.nil?
        flash.now[:error] = "Could not fetch weather data. Please try again."
      end
    end
  end
end
