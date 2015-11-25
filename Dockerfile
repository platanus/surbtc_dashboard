FROM localhost:5000/surbtc-ruby:latest

MAINTAINER Nicolas Mery Undurraga "nicolas@surbtc.com"

WORKDIR /app
ENV BUNDLE_GEMFILE=/app/Gemfile

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

ADD . /app

CMD ["bundle","exec","dashing start"]
