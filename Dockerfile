# syntax = docker/dockerfile:1.3-labs
FROM ruby:3.1.0-alpine

ENV APP_ROOT /opt/app
ENV LANG C.UTF-8
ENV RAILS_VERSION 7.0.1

RUN <<EOF
  apk update
  apk upgrade
  apk add bash
  apk add --no-cache linux-headers libxml2-dev make gcc git libc-dev nodejs tzdata postgresql-dev postgresql
  apk add --virtual build-packages --no-cache build-base curl-dev
EOF

RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
COPY . $APP_ROOT

RUN <<EOF
  gem install bundler
  gem install rails -v $RAILS_VERSION
  bundle install
EOF

EXPOSE 3000

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["rails", "server", "-b", "0.0.0.0"]
