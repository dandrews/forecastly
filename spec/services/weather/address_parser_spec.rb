require 'rails_helper'

RSpec.describe Weather::AddressParser do
  describe '#initialize' do
    context 'with invalid input' do
      it 'raises ArgumentError for blank address' do
        expect { described_class.new('') }.to raise_error(ArgumentError, 'Address cannot be blank')
        expect { described_class.new(nil) }.to raise_error(ArgumentError, 'Address cannot be blank')
        expect { described_class.new('   ') }.to raise_error(ArgumentError, 'Address cannot be blank')
      end
    end
  end

  describe '#parse' do
    subject { described_class.new(address).parse }

    context 'with single part address' do
      let(:address) { 'London' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'London',
          state: nil,
          country: nil,
          zip_code: nil,
          formatted_query: 'London'
        })
      end
    end

    context 'with city and state' do
      let(:address) { 'Portland, OR' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'Portland',
          state: 'OR',
          country: 'US',
          zip_code: nil,
          formatted_query: 'Portland,OR,US'
        })
      end
    end

    context 'with city and country' do
      let(:address) { 'Paris, France' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'Paris',
          state: nil,
          country: 'France',
          zip_code: nil,
          formatted_query: 'Paris,France'
        })
      end
    end

    context 'with city, state, and country' do
      let(:address) { 'Seattle, WA, USA' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'Seattle',
          state: 'WA',
          country: 'USA',
          zip_code: nil,
          formatted_query: 'Seattle,WA,USA'
        })
      end
    end

    context 'with multi-word city' do
      let(:address) { 'New York City, NY, USA' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'New York City',
          state: 'NY',
          country: 'USA',
          zip_code: nil,
          formatted_query: 'New York City,NY,USA'
        })
      end
    end

    context 'with special characters' do
      let(:address) { 'São Paulo, Brazil' }

      it 'returns cleaned location hash' do
        expect(subject).to eq({
          city: 'São Paulo',
          state: nil,
          country: 'Brazil',
          zip_code: nil,
          formatted_query: 'Sao Paulo,Brazil'
        })
      end
    end

    context 'with leading/trailing whitespace' do
      let(:address) { '  Portland,  OR  ' }

      it 'returns cleaned location hash' do
        expect(subject).to eq({
          city: 'Portland',
          state: 'OR',
          country: 'US',
          zip_code: nil,
          formatted_query: 'Portland,OR,US'
        })
      end
    end

    context 'with complex multi-part city' do
      let(:address) { 'Salt Lake City, UT, USA' }

      it 'correctly handles multi-part city names' do
        expect(subject).to eq({
          city: 'Salt Lake City',
          state: 'UT',
          country: 'USA',
          zip_code: nil,
          formatted_query: 'Salt Lake City,UT,USA'
        })
      end
    end

    context 'with invalid state code format' do
      let(:address) { 'Portland, Oregon, USA' }

      it 'treats non-matching state codes as part of city name' do
        expect(subject).to eq({
          city: 'Portland, Oregon',
          state: nil,
          country: 'USA',
          zip_code: nil,
          formatted_query: 'Portland, Oregon,USA'
        })
      end
    end

    context 'with zip code' do
      let(:address) { '12345' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: '',
          state: nil,
          country: nil,
          zip_code: '12345',
          formatted_query: ''
        })
      end
    end

    context 'with city and zip code' do
      let(:address) { 'Portland 97201' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'Portland',
          state: nil,
          country: nil,
          zip_code: '97201',
          formatted_query: 'Portland'
        })
      end
    end

    context 'with city, state, and zip code' do
      let(:address) { 'Portland, OR 97201' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'Portland',
          state: 'OR',
          country: 'US',
          zip_code: '97201',
          formatted_query: 'Portland,OR,US'
        })
      end
    end

    context 'with full address including zip code' do
      let(:address) { 'Portland, OR, USA 97201' }

      it 'returns correct location hash' do
        expect(subject).to eq({
          city: 'Portland',
          state: 'OR',
          country: 'USA',
          zip_code: '97201',
          formatted_query: 'Portland,OR,USA'
        })
      end
    end
  end
end
