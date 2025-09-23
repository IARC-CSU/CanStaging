# --- Stage 1: The Builder ---
# This stage will install dependencies and build the gems
FROM ruby:3.0-alpine AS builder

# Install build-time dependencies
RUN apk add --no-cache build-base

WORKDIR /app
COPY ./Gemfile* ./

# Install gems, skipping development and test groups
RUN bundle config set --local without 'development test'
RUN bundle install


# --- Stage 2: The Final Image ---
# This is the lean image that will be used in production
FROM ruby:3.0-alpine

LABEL maintainer="Morten Ervik <ervikm@iarc.who.int>"
EXPOSE 4567

# Install only RUNTIME dependencies if needed (e.g., 'tzdata' for timezones)
# RUN apk add --no-cache tzdata

ENV APP_HOME /app
WORKDIR $APP_HOME

# Copy the installed gems from the 'builder' stage
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
# Copy the application code
COPY . .

# The final command to run the app
CMD ["bundle", "exec", "rackup", "-p", "4567", "-o", "0.0.0.0"]