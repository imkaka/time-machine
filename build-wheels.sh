#!/bin/sh

# Adapted from https://github.com/pypa/python-manylinux-demo/

set -e

mkdir -p wheelhouse

# shellcheck disable=SC2016
DOCKER_SCRIPT='
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" wheel /io/ --no-deps -w "/io/wheelhouse/$PLAT/"
done

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w /io/wheelhouse/$PLAT/
    fi
}

for whl in /io/wheelhouse/$PLAT/*.whl; do
    repair_wheel "$whl"
    rm "$whl"
done'

docker run --rm -e PLAT=manylinux1_i686 -v "$(pwd)":/io quay.io/pypa/manylinux1_i686 linux32 bash -c "$DOCKER_SCRIPT"
docker run --rm -e PLAT=manylinux2010_x86_64 -v "$(pwd)":/io quay.io/pypa/manylinux2010_x86_64 bash -c "$DOCKER_SCRIPT"

# Only singly tagged wheels
find wheelhouse -iname '*manylinux*manylinux*' -delete

# macOS wheels
PIP_REQUIRE_VIRTUALENV='' python3.6 -m pip install -U pip wheel
python3.6 setup.py bdist_wheel --dist-dir wheelhouse
PIP_REQUIRE_VIRTUALENV='' python3.7 -m pip install -U pip wheel
python3.7 setup.py bdist_wheel --dist-dir wheelhouse
PIP_REQUIRE_VIRTUALENV='' python3.8 -m pip install -U pip wheel
python3.8 setup.py bdist_wheel --dist-dir wheelhouse
PIP_REQUIRE_VIRTUALENV='' python3.9 -m pip install -U pip wheel
python3.9 setup.py bdist_wheel --dist-dir wheelhouse

twine check wheelhouse/*.whl wheelhouse/*/*.whl
