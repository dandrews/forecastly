require 'rails_helper'

RSpec.describe Weather::Forecast do
  let(:forecast_service) { described_class.new }
  let(:coordinates) do
    double(
      'Coordinates',
      name: 'New York',
      latitude: 40.7128,
      longitude: -74.0060,
      state: 'NY',
      country: 'US',
      zip_code: '10001'
    )
  end

  describe '#call' do
    context 'when coordinates are nil' do
      it 'returns nil' do
        expect(forecast_service.call(nil)).to be_nil
      end
    end

    context 'when cached data exists' do
      let(:cached_weather) do
        {
          current_temp: 72,
          high_temp: 75,
          low_temp: 65,
          description: 'clear sky',
          city: 'New York',
          state: 'NY',
          country: 'US'
        }
      end

      before do
        allow(Rails.cache).to receive(:read)
          .with('weather:forecast:zip:10001')
          .and_return(cached_weather)
      end

      it 'returns cached weather data with cached flag' do
        expect(forecast_service.call(coordinates)).to eq(cached_weather.merge(cached: true))
      end
    end

    context 'when fetching new weather data' do
      let(:api_response) do
        {
          'current' => {
            'temp' => 72.5,
            'weather' => [ { 'description' => 'clear sky' } ]
          },
          'daily' => [ {
            'temp' => {
              'max' => 75.6,
              'min' => 65.4
            }
          } ]
        }
      end

      let(:expected_weather) do
        {
          current_temp: 73,
          high_temp: 76,
          low_temp: 65,
          description: 'clear sky',
          city: 'New York',
          state: 'NY',
          country: 'US',
          zip_code: '10001',
          cached: false
        }
      end

      before do
        allow(Rails.cache).to receive(:read)
          .with('weather:forecast:zip:10001')
          .and_return(nil)
        allow(Rails.cache).to receive(:write)

        stub_request(:get, Weather::Forecast::BASE_URL)
          .with(
            query: {
              lat: coordinates.latitude,
              lon: coordinates.longitude,
              appid: ENV['OPENWEATHER_API_KEY'],
              units: 'imperial',
              exclude: 'minutely,hourly,alerts'
            }
          )
          .to_return(
            status: 200,
            body: api_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches and caches weather data' do
        expect(forecast_service.call(coordinates)).to eq(expected_weather)
        expect(Rails.cache).to have_received(:write)
          .with('weather:forecast:zip:10001', expected_weather.except(:cached), expires_in: 30.minutes)
      end
    end

    context 'when API request fails' do
      before do
        allow(Rails.cache).to receive(:read)
          .with('weather:forecast:zip:10001')
          .and_return(nil)
        allow(Rails.logger).to receive(:error)

        stub_request(:get, "#{Weather::Forecast::BASE_URL}")
          .with(
            query: {
              lat: coordinates.latitude,
              lon: coordinates.longitude,
              appid: ENV['OPENWEATHER_API_KEY'],
              units: 'imperial',
              exclude: 'minutely,hourly,alerts'
            }
          )
          .to_return(status: 500)
      end

      it 'returns nil and logs error' do
        expect(forecast_service.call(coordinates)).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Error fetching weather/)
      end
    end

    context 'when API returns invalid data' do
      before do
        allow(Rails.cache).to receive(:read)
          .with('weather:forecast:zip:10001')
          .and_return(nil)

        stub_request(:get, Weather::Forecast::BASE_URL)
          .with(
            query: {
              lat: coordinates.latitude,
              lon: coordinates.longitude,
              appid: ENV['OPENWEATHER_API_KEY'],
              units: 'imperial',
              exclude: 'minutely,hourly,alerts'
            }
          )
          .to_return(
            status: 200,
            body: { invalid: 'data' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns nil' do
        expect(forecast_service.call(coordinates)).to be_nil
      end
    end
  end
end
