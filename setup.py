from setuptools import find_packages, setup

setup(
    name="posix_spawn",
    version="0.1",
    description="CFFI bindings to posix_spawn.",
    license="MIT",

    packages=find_packages(),
    package_data={"posix_spawn": ["c/*"]},

    zip_safe=False,
    ext_packages="posix_spawn"
)
