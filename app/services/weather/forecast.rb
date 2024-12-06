module Weather
  # Handles fetching and caching weather forecast data from OpenWeather API
  # @see https://openweathermap.org/api/one-call-3
  #
  # @decomposition
  #   - Forecast: Main class responsible for weather data retrieval and caching
  #   - Cache Management: Handles storing and retrieving weather data from Rails cache
  #   - API Integration: Manages OpenWeather API communication and response parsing
  #   - Error Handling: Provides robust error handling for API and parsing failures
  #
  # @design_patterns
  #   - Service Object Pattern: Encapsulates weather fetching logic in a single responsibility class
  #   - Proxy Pattern: Uses caching as a proxy to avoid unnecessary API calls
  #   - Null Object Pattern: Returns nil for invalid coordinates or failed requests
  #   - Template Method Pattern: Defines skeleton of weather fetching algorithm with private methods
  class Forecast
    include HTTParty

    # OpenWeather API endpoint for One Call API 3.0
    # @api private
    BASE_URL = "https://api.openweathermap.org/data/3.0/onecall"

    # Fetches weather data for given coordinates, using cache when available
    # @param coordinates [Coordinates] Object containing latitude, longitude, and location details
    # @option coordinates [Float] :latitude The latitude coordinate
    # @option coordinates [Float] :longitude The longitude coordinate
    # @option coordinates [String] :name City name
    # @option coordinates [String] :state State name
    # @option coordinates [String] :country Country code
    # @option coordinates [String] :zip_code ZIP/Postal code
    # @return [Hash, nil] Weather data hash containing current conditions and forecast,
    #   or nil if fetch fails
    # @example
    #   forecast = Weather::Forecast.new
    #   data = forecast.call(coordinates)
    #   puts data[:current_temp] # => 72
    def call(coordinates)
      return nil unless coordinates&.latitude && coordinates&.longitude

      cache_key = build_cache_key(coordinates)
      cached_data = fetch_from_cache(cache_key)
      return cached_data.merge(cached: true) if cached_data

      fetch_and_cache_weather(coordinates, cache_key)
    end

    private

    # Attempts to fetch weather data from Rails cache
    # @param cache_key [String] Cache key for stored weather data
    # @return [Hash, nil] Cached weather data containing temperature and location info,
    #   or nil if not found in cache
    def fetch_from_cache(cache_key)
      Rails.cache.read(cache_key)
    end

    # Fetches fresh weather data from API and caches it
    # @param coordinates [Coordinates] Location coordinates object
    # @param cache_key [String] Cache key for storing weather data
    # @return [Hash, nil] Weather data hash containing:
    #   - current_temp [Integer] Current temperature in Fahrenheit
    #   - high_temp [Integer] Forecasted high temperature
    #   - low_temp [Integer] Forecasted low temperature
    #   - description [String] Weather condition description
    #   - city [String] City name
    #   - state [String] State name
    #   - country [String] Country code
    #   - zip_code [String] ZIP/Postal code
    #   - cached [Boolean] Whether data came from cache
    # @raise [StandardError] If API request fails or response parsing fails
    def fetch_and_cache_weather(coordinates, cache_key)
      response = HTTParty.get(
        BASE_URL,
        query: {
          lat: coordinates.latitude,
          lon: coordinates.longitude,
          appid: ENV["OPENWEATHER_API_KEY"],
          units: "imperial", # Use Fahrenheit for temperature
          exclude: "minutely,hourly,alerts" # Exclude unnecessary data to reduce payload
        }
      )

      if response.success?
        Rails.logger.debug("Raw API Response: #{response.inspect}")

        # Safely parse JSON response
        parsed_response = JSON.parse(response.body) rescue nil
        return nil unless parsed_response && parsed_response["current"] && parsed_response["daily"]

        # Extract relevant weather data from response
        today_forecast = parsed_response["daily"].first
        weather_data = {
          current_temp: parsed_response["current"]["temp"].round,
          high_temp: today_forecast["temp"]["max"].round,
          low_temp: today_forecast["temp"]["min"].round,
          description: parsed_response["current"]["weather"].first["description"],
          city: coordinates.name,
          state: coordinates.state,
          country: coordinates.country,
          zip_code: coordinates.zip_code,
          cached: false
        }

        # Cache weather data for exactly 30 minutes
        Rails.cache.write(cache_key, weather_data.except(:cached), expires_in: 30.minutes)
        weather_data
      else
        Rails.logger.error("Error fetching weather data: #{response.code}")
        nil
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching weather data: #{e.message}")
      nil
    end

    # Builds a cache key for weather data based on location
    # @param coordinates [Coordinates] Location coordinates object
    # @return [String] Cache key in format "weather:forecast:zip:{zip_code}" or
    #   "weather:forecast:coords:{lat},{lon}"
    # @api private
    def build_cache_key(coordinates)
      if coordinates.zip_code.present?
        "weather:forecast:zip:#{coordinates.zip_code}"
      else
        # Fall back to lat/long based cache key if no zip code
        "weather:forecast:coords:#{coordinates.latitude},#{coordinates.longitude}"
      end
    end
  end
end
