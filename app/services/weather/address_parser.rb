module Weather
  # Parses various address formats into structured location data
  #
  # @example Parse a US address with zip code
  #   parser = AddressParser.new("New York, NY 10001")
  #   parser.parse #=> { city: "New York", state: "NY", country: "US", zip_code: "10001" }
  # @example Parse an international address
  #   parser = AddressParser.new("Paris, France")
  #   parser.parse #=> { city: "Paris", state: nil, country: "France", zip_code: nil }
  # @example Parse a state code only
  #   parser = AddressParser.new("TX")
  #   parser.parse #=> { city: nil, state: "TX", country: nil, zip_code: nil }
  #
  # @decomposition
  #   - AddressParser: Main class responsible for parsing address strings
  #   - Parsing Strategy: Uses different parsing methods based on address format
  #   - Location Builder: Constructs location hash from parsed components
  #   - Query Formatter: Formats parsed data into normalized query string
  #
  # @design_patterns
  #   - Strategy Pattern: Uses different parsing strategies based on address format
  #   - Builder Pattern: Constructs complex location hash objects step by step
  #   - Single Responsibility Principle: Each method handles one specific parsing task
  class AddressParser
    # Matches exactly 2 letters (case-insensitive) for US state codes
    # @api private
    VALID_STATE_CODE_REGEX = /\A[A-Za-z]{2}\z/.freeze
    # Matches exactly 5 digits for US zip codes
    # @api private
    ZIP_CODE_REGEX = /\b\d{5}\b/.freeze
    private_constant :VALID_STATE_CODE_REGEX, :ZIP_CODE_REGEX

    # Initializes a new AddressParser instance
    # @param address [String] The address string to parse
    # @raise [ArgumentError] if address is blank
    # @return [AddressParser] a new instance of AddressParser
    def initialize(address)
      @address = address.to_s.strip
      raise ArgumentError, "Address cannot be blank" if @address.blank?
    end

    # Parses the address into structured location data
    # @return [Hash] Parsed location data
    # @option return [String, nil] :city The city name if present
    # @option return [String, nil] :state The state code if present
    # @option return [String, nil] :country The country name if present
    # @option return [String, nil] :zip_code The zip code if present
    # @option return [String] :formatted_query Normalized query string
    def parse
      zip_code = extract_zip_code(@address)
      cleaned_address = remove_zip_code(@address)

      address_parts = cleaned_address.split(",").map(&:strip)
      location = build_location(address_parts)

      location.merge(
        zip_code: zip_code,
        formatted_query: build_formatted_query(location)
      )
    end

    private

    # Extracts and returns the zip code if present in the address
    # @param address [String] The address string to extract from
    # @return [String, nil] The zip code if found, nil otherwise
    def extract_zip_code(address)
      address.match(ZIP_CODE_REGEX)&.to_s
    end

    # Removes zip code and normalizes whitespace in the address
    # @param address [String] The address string to clean
    # @return [String] The cleaned address string
    def remove_zip_code(address)
      address.gsub(ZIP_CODE_REGEX, "").gsub(/\s+/, " ").strip
    end

    # Routes to appropriate parsing method based on number of comma-separated parts
    # @param parts [Array<String>] Array of address components
    # @return [Hash] Location data with :city, :state, and :country keys
    def build_location(parts)
      case parts.length
      when 1 then parse_single_part(parts)
      when 2 then parse_double_part(parts)
      else parse_multiple_parts(parts)
      end
    end

    # Handles single part addresses (e.g., "New York" or "NY")
    # @param parts [Array<String>] Single-element array containing the address part
    # @return [Hash] Location data with :city, :state, and :country keys
    def parse_single_part(parts)
      part = parts[0]
      return { city: nil, state: nil, country: nil } if part.blank?

      if state_code?(part)
        { city: nil, state: part.upcase, country: nil }
      else
        { city: part, state: nil, country: nil }
      end
    end

    # Handles two-part addresses (e.g., "New York, NY" or "Paris, France")
    # @param parts [Array<String>] Two-element array containing city and location code
    # @return [Hash] Location data with :city, :state, and :country keys
    def parse_double_part(parts)
      city, location_code = parts

      if state_code?(location_code)
        {
          city: city,
          state: location_code.upcase,
          country: "US"  # Default to US when we have a state code
        }
      else
        {
          city: city,
          state: nil,
          country: location_code
        }
      end
    end

    # Handles addresses with 3+ parts (e.g., "Brooklyn, NY, US")
    # @param parts [Array<String>] Array of address components
    # @return [Hash] Location data with :city, :state, and :country keys
    def parse_multiple_parts(parts)
      if state_code?(parts[-2])
        {
          city: parts[0..-3].join(", "),  # Combines all parts before state as city
          state: parts[-2].upcase,
          country: parts[-1]
        }
      else
        {
          city: parts[0..-2].join(", "),
          state: nil,
          country: parts[-1]
        }
      end
    end

    # Checks if the given code matches US state code format
    # @param code [String, nil] The code to check
    # @return [Boolean] true if code matches state code format, false otherwise
    def state_code?(code)
      return false if code.nil?
      code.match?(VALID_STATE_CODE_REGEX)
    end

    # Builds a normalized, comma-separated query string from location components
    # @param location [Hash] Location data hash
    # @option location [String, nil] :city The city name
    # @option location [String, nil] :state The state code
    # @option location [String, nil] :country The country name
    # @option location [String, nil] :zip_code The zip code
    # @return [String] Normalized, comma-separated query string
    def build_formatted_query(location)
      parts = []
      parts << location[:city] if location[:city].present?
      parts << location[:state] if location[:state].present?
      parts << location[:country] if location[:country].present?
      parts << location[:zip_code] if location[:zip_code].present?

      parts.map { |part| I18n.transliterate(part).strip }
           .compact
           .join(",")
    end
  end
end
