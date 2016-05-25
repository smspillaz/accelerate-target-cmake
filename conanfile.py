from conans import ConanFile
from conans.tools import download, unzip
import os

VERSION = "0.0.1"


class AccelerateTargetCMakeConan(ConanFile):
    name = "accelerate-target-cmake"
    version = os.environ.get("CONAN_VERSION_OVERRIDE", VERSION)
    generators = "cmake"
    requires = ("cmake-include-guard/master@smspillaz/cmake-include-guard",
                "cmake-multi-targets/master@smspillaz/cmake-multi-targets",
                "tooling-cmake-util/master@smspillaz/tooling-cmake-util",
                "cmake-unit/master@smspillaz/cmake-unit",
                "cotire/1.6.6@smspillaz/cotire")
    url = "http://github.com/polysquare/accelerate-target-cmake"
    license = "MIT"
    options = {
        "dev": [True, False]
    }
    default_options = "dev=False"

    def requirements(self):
        if self.options.dev:
            self.requires("cmake-module-common/master@smspillaz/cmake-module-common")

    def source(self):
        zip_name = "accelerate-target-cmake.zip"
        download("https://github.com/polysquare/"
                 "accelerate-target-cmake/archive/{version}.zip"
                 "".format(version="v" + VERSION),
                 zip_name)
        unzip(zip_name)
        os.unlink(zip_name)

    def package(self):
        self.copy(pattern="*.cmake",
                  dst="cmake/accelerate-target-cmake",
                  src="accelerate-target-cmake-" + VERSION,
                  keep_path=True)
