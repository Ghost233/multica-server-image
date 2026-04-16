# multica-server-image

Packaging repository for building and publishing a Docker image for the Multica Go server.

## What this repo does

- Checks out upstream source from `multica-ai/multica`
- Builds the `server` and `migrate` binaries from `server/`
- Publishes release and dev runtime images to GHCR

This repo does not deploy anything automatically. It only produces images.

## Channels

There are two packaging channels:

- `release`: for upstream version tags such as `v0.2.0`
- `dev`: for the latest upstream `main` commit

Release images are published with tags like:

- `ghcr.io/ghost233/multica-server-image:v0.2.0`
- `ghcr.io/ghost233/multica-server-image:sha-<short-sha>`
- optional `ghcr.io/ghost233/multica-server-image:latest`

Dev images are published with tags like:

- `ghcr.io/ghost233/multica-server-image:dev`
- `ghcr.io/ghost233/multica-server-image:dev-<short-sha>`

This keeps upstream `main` packaging on the dev line and out of the normal release tags.

## Manual build

Run the `Build and Publish Image` workflow manually and provide an upstream ref such as:

- `v0.2.0`
- `main`
- a commit SHA

The workflow accepts a `channel` input:

- `auto`: version tags go to `release`; branches and SHAs go to `dev`
- `release`: force release tagging
- `dev`: force dev tagging

`push_latest=true` only matters for release builds.

## Scheduled sync

The `Sync Upstream Images` workflow runs daily and can also be triggered manually.

Each run does two checks:

1. Looks up the latest upstream release tag and builds it only if that release tag is not already present in GHCR.
2. Looks up the current upstream `main` commit and builds it only if the matching `dev-<short-sha>` image is not already present in GHCR.

This means:

- new upstream releases are automatically packaged into the release channel
- upstream `main` is automatically packaged into the dev channel
- existing release/dev images are not rebuilt unnecessarily

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
