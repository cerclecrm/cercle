FROM edib/elixir-phoenix-dev:1.4
MAINTAINER John Dave Decano <johndavedecano@gmail.com>

RUN npm install -g --silent brunch

WORKDIR /app
