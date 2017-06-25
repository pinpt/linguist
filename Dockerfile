FROM ruby:2.4.1-alpine

ENV LINGUIST_VERSION 5.0.11
ENV PUMA_VERSION 3.9.1
ENV JSON_VERSION 2.1.0

RUN apk --update upgrade && \
	apk add \
		curl \
		ca-certificates \
		cmake \
		icu-dev \
		alpine-sdk && \
	gem install github-linguist:${LINGUIST_VERSION} json:${JSON_VERSION} puma:${PUMA_VERSION} --no-document && \
	apk del \
		musl-dev \
		make \
		sudo \
		tar \
		git \
		cmake \
		alpine-sdk && \
	rm -rf /var/cache/apk/*

EXPOSE 25032

WORKDIR /app

ARG VERSION
ARG BUILD
ARG NAME
ARG COMMITSHA
ARG REPO_ID

ENV VERSION ${VERSION}
ENV BUILD ${BUILD}

LABEL "io.pinpt.build.commit=${COMMITSHA}"  "io.pinpt.build.version=${VERSION}"  "io.pinpt.build.repo.id=${REPO_ID}"

COPY linguist.rb /app
COPY server.crt /app
COPY server.key /app

ENTRYPOINT ["puma", "-C", "/app/linguist.rb"]

HEALTHCHECK --interval=10s --timeout=5s CMD curl -s --fail -k https://localhost:25032/check-status || exit 1
