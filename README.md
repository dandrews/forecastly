# Forecastly

A Ruby on Rails weather application that provides current weather information based on user-provided addresses using the OpenWeatherMap API.

![Forecastly Weather App](/public/forecastly.png)

## Features

- Real-time weather data for any address worldwide
- Temperature display in Fahrenheit
- Response caching for improved performance
- Mobile-responsive design

## Architecture

- MVC architecture following Rails conventions
- Service objects for API interactions

## Monitoring and Error Handling

- Error logging with Rails logger
- Fallback behavior for API failures
- Cache hit/miss monitoring


## Browser Support

- Chrome (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Edge (latest 2 versions)

## Known Limitations

- Free tier API rate limits (60 calls/minute)
- Weather data updates every 30 minutes (cached)
- Limited to current weather (no forecasting in free tier)
- Some remote locations may not have accurate data

## Prerequisites

- Ruby 3.x
- Rails 7.2.x
- OpenWeatherMap API key

## Dependencies Installation

### macOS (using Homebrew)

1. Install Homebrew if not already installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install Ruby:

```bash
brew install ruby
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

3. Install Rails:

```bash
gem install rails -v 7.2.0
```

### Ubuntu/Debian

1. Install Ruby dependencies:

```bash
sudo apt update
sudo apt install ruby-full ruby-bundler git curl
```

2. Install Rails:

```bash
gem install rails -v 7.2.0
```

## Setup

1. Clone the repository:

```bash
git clone https://github.com/dandrews/forecastly.git
cd forecastly
```

2. Install dependencies:

```bash
bundle install
```

3. Set up environment variables:

```bash
cp .env.example .env
```
Edit `.env` and add your OpenWeatherMap API key:
```
OPENWEATHER_API_KEY=your_api_key_here
```

4. Start the Rails server:

```bash
rails server
```

The application will be available at `http://localhost:3000`

## OpenWeatherMap API Setup

1. Sign up for a free account at [OpenWeatherMap](https://openweathermap.org/api)
2. Navigate to your API keys section
3. Generate a new API key
4. The application uses two OpenWeatherMap API endpoints:
   - Geocoding API (`/geo/1.0/direct`)
   - Current Weather API (`/data/2.5/weather`)

Note: Free tier API limits:
- 60 calls/minute for weather data
- 60 calls/minute for geocoding

## Running Tests

The application uses RSpec for testing. To run the test suite:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/file_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

## Development

- Environment variables are managed through the `dotenv-rails` gem
- Code styling follows Rails Omakase conventions (via RuboCop)

### Caching

The application uses Rails' built-in caching system to improve performance:

#### Development Environment
- Caching is disabled by default in development
- To enable caching in development:
  ```bash
  rails dev:cache
  ```
- This creates `tmp/caching-dev.txt` and enables an in-memory cache store
- To disable caching, run the same command again
- Cache is automatically cleared on server restart

#### Production Environment
For production deployments, it's recommended to use Redis as the cache store for better scalability:

1. Add to your Gemfile:
   ```ruby
   gem 'redis'
   ```

2. Configure in `config/environments/production.rb`:
   ```ruby
   config.cache_store = :redis_cache_store, {
     url: ENV['REDIS_URL'],
     pool_size: 5,
     pool_timeout: 5
   }
   ```

3. Set the `REDIS_URL` environment variable in production

Redis caching provides:
- Shared cache across multiple application servers
- Persistent cache that survives application restarts
- Better memory management
- Built-in cache expiration


## Troubleshooting

Common issues and solutions:

1. **API Key Issues**
   - Verify key in `.env`
   - Check API call limits
   - Ensure proper key activation (takes ~2 hours after registration)

2. **Address Not Found**
   - Try different address formats
   - Verify location is supported by OpenWeatherMap

## Performance Optimization

- Asset compression and minification
- Database query optimization
- API request batching

## Docker Setup

### Prerequisites
- Docker
- Docker Compose

### Quick Start

1. Build and start the application:

```bash
docker-compose up --build
```

The application will be available at `http://localhost:3000`

### Docker Configuration

The application includes the following services:
- Web application (Rails)

1. Build the images:

```bash
docker-compose build
```

2. Set up the environment:

```bash
cp .env.example .env
```
Edit `.env` with your OpenWeatherMap API key.

3. Start services:

```bash
docker-compose up
```

4. Run commands inside the container:

```bash
# Rails console
docker-compose exec web rails console

# Run tests
docker-compose exec web bundle exec rspec
```

### Development with Docker

- Changes to the codebase will automatically reload in development
- Logs can be viewed using `docker-compose logs -f`
- Stop all services with `docker-compose down`
- Remove all containers and volumes with `docker-compose down -v`


## Documentation

The project uses YARD for documentation. YARD docs are available for classes, modules, and methods throughout the codebase.

### Viewing Documentation

1. Generate the docs:
```bash
yard doc
```

2. Either:
   - Start the YARD server:
   ```bash
   yard server
   ```
   - Or view directly in your browser:
   ```bash
   open doc/index.html  # On macOS/Linux
   ```

3. If using the server, view the documentation at `http://localhost:8808`

### Documentation Coverage

- All public methods include YARD documentation
- Documentation includes:
  - Method parameters and return values
  - Usage examples
  - Edge cases and exceptions
  - Related methods and see-also references

To check documentation coverage:
```bash
yard stats --list-undoc
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## License

MIT License

Copyright (c) 2024 dandrews

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.