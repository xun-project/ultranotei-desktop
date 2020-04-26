# Build DEB archive for Ubuntu 17.10 using Docker

Note: You need to have [Docker](https://docker.com) installed and the deamon running.

From the repository's top-level directory call

```
docker run --rm -v $(pwd):/source ubuntu:17.10 sh -c /source/contrib/ubuntu/build.sh
```

The resulting archive is located at `build/release/UltraNoteWallet-<version>.amd64.deb`.
