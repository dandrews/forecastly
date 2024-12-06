# Module for handling weather-related functionality
module Weather
  # Client for retrieving weather forecasts based on addresses
  # Coordinates the process of converting addresses to coordinates and fetching forecast data
  #
  # @example
  #   Weather::Client.get_weather("123 Main St, City, State")
  #
  # @decomposition
  #   This service is decomposed into three main components:
  #   - Weather::Client: Orchestrates the overall process and handles error management
  #   - LocationLookup: Responsible for converting addresses to coordinates
  #   - Forecast: Handles weather API interactions and data retrieval
  #
  # @design_patterns
  #   - Facade Pattern: Acts as a simplified interface to the complex subsystem of geocoding and weather lookup
  #   - Service Object Pattern: Encapsulates business logic for weather retrieval
  #   - Factory Method Pattern: Class method get_weather creates instances as needed
  class Client
    # @raise [Weather::Client::Error] Base error class for Weather::Client
    class Error < StandardError; end

    # Retrieves weather forecast for a given address
    # @param address [String] The address to get weather for (e.g., "123 Main St, City, State")
    # @return [Hash] Weather forecast data containing temperature, conditions, etc.
    # @raise [Weather::Client::Error] If the address is invalid or weather lookup fails
    def self.get_weather(address)
      new.get_weather(address)
    end

    # Retrieves detailed weather forecast for a given address by converting it to coordinates
    # @param address [String] The address to get weather for (e.g., "123 Main St, City, State")
    # @return [Hash] Weather forecast data containing temperature, conditions, etc.
    # @raise [Weather::Client::Error] If the address is invalid or weather lookup fails
    # @raise [LocationLookup::Error] If the address cannot be geocoded
    # @raise [Forecast::Error] If the weather service request fails
    def get_weather(address)
      validate_address!(address)
      coordinates = LocationLookup.new.call(address)
      Forecast.new.call(coordinates)
    rescue LocationLookup::Error, Forecast::Error => e
      Rails.logger.error("Weather lookup failed: #{e.message}")
      raise Error, "Failed to retrieve weather data: #{e.message}"
    end

    private

    # Validates that the provided address is not blank or nil
    # @param address [String] The address to validate
    # @raise [Weather::Client::Error] If the address is blank or nil
    def validate_address!(address)
      raise Error, "Address cannot be blank" if address.blank?
    end
  end
end
