set(OpenEXR_GIT https://github.com/AcademySoftwareFoundation/openexr)
set(OpenEXR_TAG RB-3.1)
set(OpenEXR_CMAKE_ARGS
    -DILMBASE_NAMESPACE_VERSIONING=OFF
    -DOPENEXR_NAMESPACE_VERSIONING=OFF
    -DOPENEXR_BUILD_SHARED_LIBS=OFF
    -DILMBASE_BUILD_SHARED_LIBS=OFF
)
set(OpenEXR_SHARED_LIBS OFF)