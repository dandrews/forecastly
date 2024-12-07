require 'rails_helper'

RSpec.describe Weather::LocationLookup do
  let(:service) { described_class.new }
  let(:address) { "New York, NY" }
  let(:parsed_location) { { formatted_query: "New York,NY,US" } }
  let(:api_key) { 'test_api_key' }
  let(:api_response) do
    [
      {
        "name" => "New York",
        "lat" => 40.7128,
        "lon" => -74.0060,
        "country" => "US",
        "state" => "New York"
      }
    ]
  end
  let(:zip_code) { "10001" }
  let(:zip_response) do
    {
      "name" => "New York",
      "lat" => 40.7128,
      "lon" => -74.0060,
      "country" => "US",
      "state" => "New York"
    }
  end
  let(:base_url) { "http://api.openweathermap.org/geo/1.0" }

  before do
    # Setup default API key stub
    allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(api_key)
    allow(Rails.application.credentials).to receive(:openweather).and_return({ api_key: nil })
  end

  describe '#call' do
    before do
      allow_any_instance_of(Weather::AddressParser)
        .to receive(:parse)
        .and_return(parsed_location)
    end

    context 'when API request is successful' do
      before do
        stub_request(:get, "#{base_url}/direct")
          .with(
            query: {
              q: parsed_location[:formatted_query],
              limit: 1,
              appid: ENV['OPENWEATHER_API_KEY']
            }
          )
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns coordinates object with correct data' do
        result = service.call(address)

        expect(result).to be_a(Weather::Coordinates)
        expect(result.name).to eq('New York')
        expect(result.latitude).to eq(40.7128)
        expect(result.longitude).to eq(-74.0060)
        expect(result.country).to eq('US')
        expect(result.state).to eq('New York')
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get, "#{base_url}/direct")
          .with(
            query: {
              q: parsed_location[:formatted_query],
              limit: 1,
              appid: ENV['OPENWEATHER_API_KEY']
            }
          )
          .to_raise(StandardError.new("Internal Server Error"))
      end

      it 'raises a GeocodingError' do
        expect(Rails.logger).to receive(:error).with(/Error fetching coordinates: Internal Server Error/)

        expect {
          service.call(address)
        }.to raise_error(Weather::GeocodingError, /Failed to fetch coordinates: Internal Server Error/)
      end
    end

    context 'when API returns empty results' do
      before do
        stub_request(:get, "#{base_url}/direct")
          .with(
            query: {
              q: parsed_location[:formatted_query],
              limit: 1,
              appid: ENV['OPENWEATHER_API_KEY']
            }
          )
          .to_return(
            status: 200,
            body: '[]',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns nil' do
        expect(service.call(address)).to be_nil
      end
    end

    context 'when API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(nil)
        allow(Rails.application.credentials).to receive(:openweather).and_return({ api_key: nil })
      end

      it 'raises a ConfigurationError' do
        expect {
          service.call(address)
        }.to raise_error(Weather::ConfigurationError, /Missing OpenWeather API key/)
      end
    end

    context 'when API key is available in credentials' do
      let(:credentials_api_key) { 'credentials_test_key' }

      before do
        allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(nil)
        allow(Rails.application.credentials).to receive(:openweather).and_return({ api_key: credentials_api_key })

        stub_request(:get, "#{base_url}/direct")
          .with(
            query: {
              q: parsed_location[:formatted_query],
              limit: 1,
              appid: credentials_api_key
            }
          )
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'uses the API key from credentials' do
        result = service.call(address)
        expect(result).to be_a(Weather::Coordinates)
      end
    end

    context 'when credentials are not configured' do
      before do
        allow(ENV).to receive(:[]).with('OPENWEATHER_API_KEY').and_return(nil)
        allow(Rails.application.credentials).to receive(:openweather).and_return(nil)
      end

      it 'raises a ConfigurationError with appropriate message' do
        expect {
          service.call(address)
        }.to raise_error(Weather::ConfigurationError, /OpenWeather credentials not configured/)
      end
    end

    context 'when location includes ZIP code' do
      let(:parsed_location) { { zip_code: zip_code, formatted_query: "New York,NY,US" } }

      context 'when ZIP lookup is successful' do
        before do
          stub_request(:get, "#{base_url}/zip")
            .with(
              query: {
                zip: zip_code,
                country: "US",
                appid: api_key
              }
            )
            .to_return(
              status: 200,
              body: zip_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'returns coordinates from ZIP lookup' do
          result = service.call(address)

          expect(result).to be_a(Weather::Coordinates)
          expect(result.name).to eq('New York')
          expect(result.latitude).to eq(40.7128)
          expect(result.longitude).to eq(-74.0060)
        end
      end

      context 'when ZIP lookup fails but direct geocoding succeeds' do
        before do
          # Stub ZIP lookup to fail
          stub_request(:get, "#{base_url}/zip")
            .with(
              query: {
                zip: zip_code,
                country: "US",
                appid: api_key
              }
            )
            .to_return(status: 404)

          # Stub direct geocoding to succeed
          stub_request(:get, "#{base_url}/direct")
            .with(
              query: {
                q: parsed_location[:formatted_query],
                limit: 1,
                appid: api_key
              }
            )
            .to_return(
              status: 200,
              body: api_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'falls back to direct geocoding' do
          result = service.call(address)

          expect(result).to be_a(Weather::Coordinates)
          expect(result.name).to eq('New York')
          expect(result.latitude).to eq(40.7128)
          expect(result.longitude).to eq(-74.0060)
        end
      end
    end
  end
end
