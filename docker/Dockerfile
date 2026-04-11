# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.8

FROM ruby:${RUBY_VERSION}-slim AS base

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

WORKDIR /rails

# Runtime-Packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        libpq5 \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*


FROM base AS build

# Build-Packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        build-essential \
        git \
        pkg-config \
        libyaml-dev \
        libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler:4.0.8

# Gems installieren
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    bundle exec bootsnap precompile --gemfile

# App kopieren
COPY . .

# Bootsnap / Assets
RUN bundle exec bootsnap precompile app/ lib/

# Für assets:precompile braucht Rails einen Secret Key
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile


FROM base

# Optional: nicht als root laufen
RUN useradd --create-home --shell /bin/bash rails
WORKDIR /rails

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

USER rails

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]