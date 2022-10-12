# Portable Test Envrionment of Gluten (gluten-te)

Build and run [gluten](https://github.com/oap-project/gluten) and [gluten-it](https://github.com/zhztheplayer/gluten-it) in a portable docker container, from scratch.

# Prerequisites

Only Linux and MacOS are currently supported. Before running the scripts, make sure you have `git` and `docker` installed in your host machine.

# Getting Started (Build Gluten code)

```sh
git clone -b main https://github.com/zhztheplayer/gluten.git gluten # Gluten main code
git clone -b main https://github.com/zhztheplayer/gluten-te.git gluten-te # gluten-te code

export HTTP_PROXY_HOST=myproxy.example.com # in case you are behind http proxy
export HTTP_PROXY_PORT=55555 # in case you are behind http proxy

cd gluten/
../gluten-it/buildhere.sh
```

# Getting Started (TPC)

```sh
git clone -b main https://github.com/zhztheplayer/gluten-te.git gluten-te
cd gluten-te
./tpc.sh
```

# Configurations

See the [config file](https://github.com/zhztheplayer/gluten-te/blob/main/defaults.conf). You can modify the file to configure gluten-te, or pass env variables during running the scripts.

# Example Usages

## Example: Build local Gluten code

```
cd gluten/
{PATH_TO_GLUTEN_TE}/buildhere.sh
```

## Example: Build local Gluten code behind a http proxy

```
cd gluten/
HTTP_PROXY_HOST=myproxy.example.com \
HTTP_PROXY_PORT=55555 \
{PATH_TO_GLUTEN_TE}/buildhere.sh
```

## Example: Build and run TPC benchmark on non-default remote branches of Gluten

```sh
TARGET_GLUTEN_REPO=my_repoh \
TARGET_GLUTEN_BRANCH=my_branch \
./tpc.sh
```

## Example: Build and run TPC benchmark on official latest code behind a http proxy

```sh
HTTP_PROXY_HOST=myproxy.example.com \
HTTP_PROXY_PORT=55555 \
./tpc.sh
```

## Example: Create debug build for all codes, and open a GDB debugger interface during running gluten-it

```sh
DEBUG_BUILD=ON \
RUN_GDB=ON \
./tpc.sh
```
