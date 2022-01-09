FROM ruby:2.7.5-bullseye

COPY Gemfile /bundle/Gemfile
COPY Gemfile.lock /bundle/Gemfile.lock

WORKDIR /bundle

RUN gem install bundler && bundle install
