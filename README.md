# Linguist

This repository provides a basic web server wrapper around the [Github Linguist](https://github.com/github/linguist) tool.
Simple container to run github linguist.

## Building

Using Docker to build is the easiest.

### Build for Development

`make`

### Build for Production

Make sure you edit the `VERSION` file with the new version and then:

`make release`

## Running

Assuming you're running in Docker:

`docker run -it --rm -p 25032:25032 pinpt/linguist`

Then test:

`curl -k -X POST --data '[{"name":"test.jsx","body":"<Hello/>"}]' -H 'Authorization: 1234' https://localhost:25032/detect`

You can change the Authorization key:

`docker run -it --rm -p 25032:25032 -e PP_LINGUIST_AUTH=5678 pinpt/linguist`

`curl -k -X POST --data '[{"name":"test.jsx","body":"<Hello/>"}]' -H 'Authorization: 5678' https://localhost:25032/detect`

You can change the TLS certificates by mounting the file at `/app/server.crt` and `/app/server.key` such as:

`docker run -it --rm -p 25032:25032 -e PP_LINGUIST_AUTH=5678 -v server.crt:/app/server.crt -v server.key:/app/server.key pinpt/linguist`

## License

Copyright (c) 2017 by PinPT, Inc. All Rights Reserved.
