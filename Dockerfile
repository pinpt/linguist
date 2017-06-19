FROM alpine

RUN apk --update upgrade && \
	apk add \
		curl \
		ca-certificates \
		git \
		make \
		gcc \
		musl-dev \
		cmake \
		pkgconfig \
		icu-dev \
		zlib-dev \
		ruby \
		ruby-dev \
		ruby-io-console \
		ruby-bigdecimal \
		ruby-json \
		alpine-sdk \
   	libstdc++ && \
	gem install github-linguist json webrick --no-document && \
	apk del \
		git \
		make \
		gcc \
		musl-dev \
		cmake \
		pkgconfig \
		zlib-dev \
		ruby-dev \
		alpine-sdk \
		libstdc++ && \
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

ENTRYPOINT ["ruby", "/app/linguist.rb"]

HEALTHCHECK --interval=5s --timeout=3s CMD curl -s --fail -k https://localhost:25032/check-status || exit 1
