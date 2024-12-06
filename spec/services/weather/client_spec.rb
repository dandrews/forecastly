require 'rails_helper'

RSpec.describe Weather::Client do
  describe '.get_weather' do
    let(:address) { '123 Main St, City, State' }
    let(:coordinates) { { latitude: 40.7128, longitude: -74.0060 } }
    let(:forecast_data) { { temperature: 72, conditions: 'sunny' } }
    let(:location_lookup) { instance_double(Weather::LocationLookup) }
    let(:forecast) { instance_double(Weather::Forecast) }

    before do
      allow(Weather::LocationLookup).to receive(:new).and_return(location_lookup)
      allow(Weather::Forecast).to receive(:new).and_return(forecast)
    end

    context 'when successful' do
      before do
        allow(location_lookup).to receive(:call).with(address).and_return(coordinates)
        allow(forecast).to receive(:call).with(coordinates).and_return(forecast_data)
      end

      it 'returns weather forecast for the given address' do
        result = described_class.get_weather(address)

        expect(location_lookup).to have_received(:call).with(address)
        expect(forecast).to have_received(:call).with(coordinates)
        expect(result).to eq(forecast_data)
      end
    end

    context 'when address is blank' do
      let(:address) { '' }

      it 'raises an error' do
        expect {
          described_class.get_weather(address)
        }.to raise_error(Weather::Client::Error, 'Address cannot be blank')
      end
    end

    context 'when location lookup fails' do
      before do
        allow(location_lookup).to receive(:call)
          .and_raise(Weather::LocationLookup::Error.new('Invalid address'))
      end

      it 'raises a client error with the appropriate message' do
        expect {
          described_class.get_weather(address)
        }.to raise_error(Weather::Client::Error, 'Failed to retrieve weather data: Invalid address')
      end
    end

    context 'when forecast lookup fails' do
      before do
        allow(location_lookup).to receive(:call).with(address).and_return(coordinates)
        allow(forecast).to receive(:call)
          .and_raise(Weather::Forecast::Error.new('API unavailable'))
      end

      it 'raises a client error with the appropriate message' do
        expect {
          described_class.get_weather(address)
        }.to raise_error(Weather::Client::Error, 'Failed to retrieve weather data: API unavailable')
      end
    end
  end
end
