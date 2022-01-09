FROM ruby:3.1.0-bullseye

COPY Gemfile /bundle/Gemfile
COPY Gemfile.lock /bundle/Gemfile.lock

WORKDIR /bundle

RUN bundle install
