# Multistage build
# Build container
FROM elixir:1.9.1-alpine as build

RUN mix local.hex --force
RUN mix local.rebar --force

# create app folder
RUN mkdir /app
COPY ./app /app
WORKDIR /app

# install dependencies
RUN mix deps.get
RUN MIX_ENV=prod mix release --env=prod

# Deployable container
FROM alpine:3.9
RUN apk --no-cache add bash curl
WORKDIR /app
COPY --from=build /app/_build/prod/rel/app/releases/0.1.0/app.tar.gz .

RUN tar xzfv app.tar.gz
WORKDIR ./bin

ARG PORT
ARG HOSTNAME
ARG PAYMENT_KEY
ENV PORT=${PORT}
ENV HOSTNAME=${HOSTNAME}
ENV PAYMENT_KEY=${PAYMENT_KEY}
EXPOSE ${PORT}

CMD ["./app", "foreground"]