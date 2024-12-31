FROM ruby:3.2

# Install PostgreSQL client
RUN apt-get update -qq && apt-get install -y postgresql-client

# Set the working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock into the image
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Default command to run the Rails server
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
