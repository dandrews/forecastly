module Weather
  # Handles geocoding addresses to coordinates using the OpenWeather Geocoding API
  # @see https://openweathermap.org/api/geocoding-api
  #
  # @decomposition
  #   This service is decomposed into three main components:
  #   - LocationLookup: Main service that orchestrates the geocoding process
  #   - AddressParser: Handles parsing and normalizing address inputs
  #   - Coordinates: Value object that encapsulates location data
  #
  # @design_patterns
  #   - Strategy Pattern: Uses different geocoding strategies (ZIP vs. direct query)
  #   - Template Method Pattern: Defines skeleton algorithm in fetch_coordinates with specialized steps
  #   - Adapter Pattern: Wraps the HTTParty client to provide a consistent interface
  class LocationLookup
    include HTTParty

    BASE_URL = "http://api.openweathermap.org/geo/1.0"
    private_constant :BASE_URL

    # Converts an address into geographic coordinates
    # @param address [String] The address to lookup coordinates for
    # @return [Weather::Coordinates] The coordinates and location details
    # @raise [Weather::GeocodingError] If coordinates cannot be fetched
    # @raise [Weather::ConfigurationError] If API key is not properly configured
    # @example Look up coordinates by ZIP code
    #   lookup = Weather::LocationLookup.new
    #   coordinates = lookup.call("90210")
    #   coordinates.latitude  #=> 34.0901
    #   coordinates.longitude #=> -118.4065
    def call(address)
      location = AddressParser.new(address).parse
      fetch_coordinates(location)
    end

    private

    # Attempts to fetch coordinates using multiple strategies
    # @param location [Hash] Location details parsed from the address
    # @option location [String, nil] :zip_code US ZIP code if available
    # @option location [String] :formatted_query Formatted address string
    # @return [Weather::Coordinates] The location coordinates
    # @raise [Weather::GeocodingError] If geocoding fails
    # @raise [Weather::ConfigurationError] If API configuration is invalid
    def fetch_coordinates(location)
      api_key = fetch_api_key

      # Try ZIP code lookup first if available
      if location[:zip_code].present?
        coordinates = fetch_by_zip(location[:zip_code], api_key)
        return coordinates if coordinates
      end

      # Fall back to direct geocoding if ZIP lookup fails or no ZIP provided
      fetch_by_query(location, api_key)
    rescue Weather::ConfigurationError
      raise # Re-raise configuration errors directly
    rescue StandardError => e
      Rails.logger.error("Error fetching coordinates: #{e.message}")
      raise Weather::GeocodingError, "Failed to fetch coordinates: #{e.message}"
    end

    # Attempts to fetch coordinates using ZIP code lookup
    # @param zip_code [String] US ZIP code
    # @param api_key [String] OpenWeather API key
    # @return [Weather::Coordinates, nil] Location coordinates if found
    private def fetch_by_zip(zip_code, api_key)
      response = client.get(
        "#{BASE_URL}/zip",
        query: {
          zip: zip_code,
          country: "US", # Assuming US ZIP codes for now
          appid: api_key
        }
      )

      Rails.logger.debug("ZIP Geocoding Response: #{response.code} - #{response.body}")

      return nil unless valid_response?(response)
      build_coordinates(response)
    end

    # Attempts to fetch coordinates using direct geocoding query
    # @param location [Hash] Location details
    # @option location [String] :formatted_query Formatted address string
    # @param api_key [String] OpenWeather API key
    # @return [Weather::Coordinates, nil] Location coordinates if found
    private def fetch_by_query(location, api_key)
      response = client.get(
        "#{BASE_URL}/direct",
        query: build_query(location, api_key)
      )

      Rails.logger.debug("Direct Geocoding Response: #{response.code} - #{response.body}")

      return nil unless valid_response?(response)
      build_coordinates(response.first)
    end

    # @return [Class] The HTTP client class
    private def client
      @client ||= HTTParty
    end

    # Builds query parameters for direct geocoding
    # @param location [Hash] Location details
    # @option location [String] :formatted_query Formatted address string
    # @param api_key [String] OpenWeather API key
    # @return [Hash] The query parameters
    private def build_query(location, api_key)
      {
        q: location[:formatted_query],
        limit: 1,
        appid: api_key
      }
    end

    # Retrieves the OpenWeather API key
    # @return [String] The API key
    # @raise [Weather::ConfigurationError] If API key is not configured
    private def fetch_api_key
      return ENV["OPENWEATHER_API_KEY"] if ENV["OPENWEATHER_API_KEY"].present?

      if Rails.application.credentials.openweather.nil?
        raise Weather::ConfigurationError, "OpenWeather credentials not configured. Run 'rails credentials:edit' to add them."
      end

      Rails.application.credentials.openweather[:api_key] ||
        raise(Weather::ConfigurationError, "Missing OpenWeather API key in credentials")
    end

    # Validates the API response
    # @param response [HTTParty::Response] The API response
    # @return [Boolean] Whether the response is valid
    private def valid_response?(response)
      return false unless response.success?
      return false if response.body.nil? || response.body.empty?

      data = response.parsed_response
      return false if data.is_a?(Array) && data.empty?
      true
    end

    # Constructs a Coordinates object from API response
    # @param response_data [Hash, Array<Hash>] Location data from API
    # @return [Weather::Coordinates] The coordinates object
    private def build_coordinates(response_data)
      data = response_data.is_a?(Array) ? response_data.first : response_data

      Coordinates.new(
        name: data["name"],
        latitude: data["lat"],
        longitude: data["lon"],
        country: data["country"],
        state: data["state"],
        zip_code: data["zip"] || data["postal_code"]
      )
    end
  end
end
