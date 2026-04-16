# multica-server-image

Packaging repository for building and publishing a Docker image for the Multica Go server.

## What this repo does

- Checks out upstream source from `multica-ai/multica`
- Builds the `server` and `migrate` binaries from `server/`
- Publishes a runtime image to GHCR

This repo does not deploy anything automatically. It only produces images.

## Build a new image

Run the `Build and Publish Image` workflow manually and provide an upstream ref such as:

- `v0.2.0`
- `main`
- a commit SHA

By default the workflow publishes:

- `ghcr.io/ghost233/multica-server-image:<upstream-ref>`
- `ghcr.io/ghost233/multica-server-image:sha-<short-sha>`

If `push_latest=true`, it also publishes:

- `ghcr.io/ghost233/multica-server-image:latest`

## Runtime behavior

The image starts the Multica server by default.

Optional environment variable:

- `RUN_MIGRATIONS_ON_START=1`

When enabled, the container runs `./migrate up` before starting `./server`.

## Example local usage

See [docker-compose.example.yml](docker-compose.example.yml).

You still need to provide real values for:

- `DATABASE_URL`
- `JWT_SECRET`
- any optional storage or auth environment variables required by your deployment
