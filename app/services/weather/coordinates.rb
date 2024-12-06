module Weather
  # Represents a geographical location using coordinates and optional location details.
  # Provides validation and serialization for location data, ensuring coordinates
  # fall within valid ranges.
  #
  # @example
  #   coords = Coordinates.new(latitude: 40.7128, longitude: -74.0060, name: "New York")
  #   coords.validate #=> true
  #   coords.to_h #=> { latitude: 40.7128, longitude: -74.0060, name: "New York" }
  #
  # @decomposition
  #   This class is decomposed into three main components:
  #   - Attributes Management: Handles coordinate and location data storage
  #   - Validation Layer: Ensures coordinate values are within valid ranges
  #   - Serialization: Converts coordinate data to standardized hash format
  #
  # @design_patterns
  #   - Value Object Pattern: Represents an immutable set of coordinates with validation
  #   - Active Model Pattern: Incorporates Rails validation framework
  #   - Builder Pattern: Allows flexible object construction through attributes hash
  class Coordinates
    include ActiveModel::API
    include ActiveModel::Validations

    # @!attribute [rw] latitude
    #   @return [Float] The latitude coordinate (-90 to 90 degrees)
    # @!attribute [rw] longitude
    #   @return [Float] The longitude coordinate (-180 to 180 degrees)
    # @!attribute [rw] name
    #   @return [String, nil] The name of the location (e.g., city name)
    # @!attribute [rw] state
    #   @return [String, nil] The state or province of the location
    # @!attribute [rw] country
    #   @return [String, nil] The country of the location
    # @!attribute [rw] zip_code
    #   @return [String, nil] The postal/zip code of the location
    attr_accessor :latitude, :longitude, :name, :state, :country, :zip_code

    validates :latitude, :longitude, presence: true
    validates :latitude,  numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
    validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

    # Initializes a new Coordinates instance with the given attributes
    #
    # @param attributes [Hash] The attributes to initialize the coordinates with
    # @option attributes [Float] :latitude The latitude coordinate (-90 to 90 degrees)
    # @option attributes [Float] :longitude The longitude coordinate (-180 to 180 degrees)
    # @option attributes [String] :name The location name
    # @option attributes [String] :state The state or province
    # @option attributes [String] :country The country
    # @option attributes [String] :zip_code The postal/zip code
    # @return [Coordinates] A new instance of Coordinates
    def initialize(attributes = {})
      attributes.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    # Converts the coordinates object to a hash representation
    #
    # @return [Hash] A hash containing all non-nil attributes with their values
    # @example
    #   coords = Coordinates.new(latitude: 40.7128, longitude: -74.0060, name: "New York")
    #   coords.to_h #=> { latitude: 40.7128, longitude: -74.0060, name: "New York" }
    def to_h
      {
        latitude: latitude,
        longitude: longitude,
        name: name,
        state: state,
        country: country,
        zip_code: zip_code
      }.compact
    end
  end
end
