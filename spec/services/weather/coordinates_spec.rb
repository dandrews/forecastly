require 'rails_helper'

RSpec.describe Weather::Coordinates do
  let(:valid_attributes) do
    {
      latitude: 40.7128,
      longitude: -74.0060,
      name: 'New York',
      state: 'NY',
      country: 'US'
    }
  end

  describe 'validations' do
    context 'when attributes are valid' do
      it 'is valid with all attributes' do
        coordinates = described_class.new(valid_attributes)
        expect(coordinates).to be_valid
      end

      it 'is valid with only required attributes' do
        coordinates = described_class.new(
          latitude: valid_attributes[:latitude],
          longitude: valid_attributes[:longitude]
        )
        expect(coordinates).to be_valid
      end
    end

    context 'when required attributes are missing' do
      it 'is invalid without latitude' do
        coordinates = described_class.new(longitude: valid_attributes[:longitude])
        expect(coordinates).not_to be_valid
        expect(coordinates.errors[:latitude]).to include("can't be blank")
      end

      it 'is invalid without longitude' do
        coordinates = described_class.new(latitude: valid_attributes[:latitude])
        expect(coordinates).not_to be_valid
        expect(coordinates.errors[:longitude]).to include("can't be blank")
      end
    end

    context 'when coordinates are out of range' do
      it 'is invalid with latitude less than -90' do
        coordinates = described_class.new(valid_attributes.merge(latitude: -91))
        expect(coordinates).not_to be_valid
        expect(coordinates.errors[:latitude]).to include('must be greater than or equal to -90')
      end

      it 'is invalid with latitude greater than 90' do
        coordinates = described_class.new(valid_attributes.merge(latitude: 91))
        expect(coordinates).not_to be_valid
        expect(coordinates.errors[:latitude]).to include('must be less than or equal to 90')
      end

      it 'is invalid with longitude less than -180' do
        coordinates = described_class.new(valid_attributes.merge(longitude: -181))
        expect(coordinates).not_to be_valid
        expect(coordinates.errors[:longitude]).to include('must be greater than or equal to -180')
      end

      it 'is invalid with longitude greater than 180' do
        coordinates = described_class.new(valid_attributes.merge(longitude: 181))
        expect(coordinates).not_to be_valid
        expect(coordinates.errors[:longitude]).to include('must be less than or equal to 180')
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash with all attributes' do
      coordinates = described_class.new(valid_attributes)
      expect(coordinates.to_h).to eq(valid_attributes)
    end

    it 'excludes nil values' do
      coordinates = described_class.new(
        latitude: valid_attributes[:latitude],
        longitude: valid_attributes[:longitude]
      )
      expect(coordinates.to_h).to eq(
        latitude: valid_attributes[:latitude],
        longitude: valid_attributes[:longitude]
      )
    end
  end

  describe 'attributes' do
    it 'allows reading and writing of attributes' do
      coordinates = described_class.new
      valid_attributes.each do |key, value|
        coordinates.public_send("#{key}=", value)
        expect(coordinates.public_send(key)).to eq(value)
      end
    end
  end
end
