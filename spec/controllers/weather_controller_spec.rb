require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  describe 'GET #index' do
    context 'when no address is provided' do
      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'does not attempt to fetch weather data' do
        expect(Weather::Client).not_to receive(:get_weather)
        get :index
      end
    end

    context 'when address is provided' do
      let(:address) { '123 Test St' }

      context 'when weather data is successfully fetched' do
        let(:weather_data) { { temperature: 72, conditions: 'sunny' } }

        before do
          allow(Weather::Client).to receive(:get_weather).with(address).and_return(weather_data)
        end

        it 'fetches weather data' do
          expect(Weather::Client).to receive(:get_weather).with(address)
          get :index, params: { address: address }
        end

        it 'assigns weather data' do
          get :index, params: { address: address }
          expect(assigns(:weather_data)).to eq(weather_data)
        end

        it 'assigns the address' do
          get :index, params: { address: address }
          expect(assigns(:address)).to eq(address)
        end
      end

      context 'when weather data fetch fails' do
        before do
          allow(Weather::Client).to receive(:get_weather).with(address).and_return(nil)
        end

        it 'sets flash error message' do
          get :index, params: { address: address }
          expect(flash.now[:error]).to eq('Could not fetch weather data. Please try again.')
        end

        it 'still assigns the address' do
          get :index, params: { address: address }
          expect(assigns(:address)).to eq(address)
        end

        it 'assigns nil to weather_data' do
          get :index, params: { address: address }
          expect(assigns(:weather_data)).to be_nil
        end
      end
    end
  end
end
