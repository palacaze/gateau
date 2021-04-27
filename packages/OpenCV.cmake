set(OpenCV_VERSION "4.5.2")
set(OpenCV_URL "https://github.com/opencv/opencv/archive/${OpenCV_VERSION}.tar.gz")
set(OpenCV_MD5 "d3141f649ab2d76595fdd8991ee15c55")
set(OpenCV_SHARED_LIBS ON)
set(OpenCV_CMAKE_ARGS
    -DWITH_MKL=ON
    -DCPU_BASELINE=AVX
    -DCPU_DISPATCH=AVX2
    -DWITH_EIGEN=ON
    -DWITH_JPEG=ON
    -DWITH_PNG=ON
    -DWITH_TBB=ON
    -DWITH_OPENMP=ON
    -DWITH_PTHREADS_PF=ON
    -DWITH_LAPACK=ON
    -DOPENCV_GENERATE_PKGCONFIG=ON
    -DENABLE_LTO=ON
    -DCMAKE_SKIP_RPATH=ON
    -DBUILD_opencv_calib3d=ON
    -DBUILD_opencv_core=ON
    -DBUILD_opencv_features2d=ON
    -DBUILD_opencv_flann=ON
    -DBUILD_opencv_highgui=ON
    -DBUILD_opencv_imgcodecs=ON
    -DBUILD_opencv_imgproc=ON
    -DBUILD_opencv_dnn=OFF
    -DBUILD_opencv_gapi=OFF
    -DBUILD_opencv_java=OFF
    -DBUILD_opencv_js=OFF
    -DBUILD_opencv_ml=OFF
    -DBUILD_opencv_objc=OFF
    -DBUILD_opencv_objdetect=OFF
    -DBUILD_opencv_photo=OFF
    -DBUILD_opencv_python=OFF
    -DBUILD_opencv_stitching=OFF
    -DBUILD_opencv_ts=OFF
    -DBUILD_opencv_video=OFF
    -DBUILD_opencv_videoio=OFF
    -DBUILD_opencv_world=OFF
    -DPYTHON_EXECUTABLE=OFF
    -DINSTALL_PYTHON_EXAMPLES=OFF
    -DBUILD_opencv_python2=OFF
    -DBUILD_opencv_python3=OFF
    -DENABLE_DOWNLOAD=OFF
    -DWITH_QUIRC=OFF
    -DWITH_1394=OFF
    -DWITH_ADE=OFF
    -DWITH_VTK=OFF
    -DWITH_VFW=OFF
    -DWITH_FFMPEG=OFF
    -DWITH_GSTREAMER=OFF
    -DWITH_GSTREAMER_0_10=OFF
    -DWITH_GTK=OFF
    -DWITH_GTK_2_X=OFF
    -DWITH_IPP=OFF
    -DWITH_JASPER=OFF
    -DWITH_WEBP=OFF
    -DWITH_OPENEXR=OFF
    -DWITH_OPENGL=OFF
    -DWITH_OPENVX=OFF
    -DWITH_OPENNI=OFF
    -DWITH_OPENNI2=OFF
    -DWITH_GDCM=OFF
    -DWITH_PVAPI=OFF
    -DWITH_GIGEAPI=OFF
    -DWITH_ARAVIS=OFF
    -DWITH_QT=OFF
    -DWITH_WIN32UI=OFF
    -DWITH_TIFF=OFF
    -DWITH_OPENJPEG=OFF
    -DWITH_UNICAP=OFF
    -DWITH_V4L=OFF
    -DWITH_LIBV4L=OFF
    -DWITH_MSMF=OFF
    -DWITH_XIMEA=OFF
    -DWITH_XINE=OFF
    -DWITH_CLP=OFF
    -DWITH_OPENCL=OFF
    -DWITH_OPENCL_SVM=OFF
    -DWITH_OPENCLAMDFFT=OFF
    -DWITH_OPENCLAMDBLAS=OFF
    -DWITH_DIRECTX=OFF
    -DWITH_INTELPERC=OFF
    -DWITH_IPP_A=OFF
    -DWITH_MATLAB=OFF
    -DWITH_VA=OFF
    -DWITH_VA_INTEL=OFF
    -DWITH_GDAL=OFF
    -DWITH_GPHOTO2=OFF
    -DWITH_ITT=OFF
    -DWITH_CUDA=OFF
    -DWITH_CUBLAS=OFF
    -DWITH_CUFFT=OFF
    -DWITH_NVCUVID=OFF
    -DWITH_PROTOBUF=OFF
    -DCUDA_NPP_LIBRARY_ROOT_DIR=
    -DBUILD_JAVA=OFF
    -DBUILD_ANDROID_EXAMPLES=OFF
    -DBUILD_opencv_apps=OFF
    -DBUILD_DOCS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_PERF_TESTS=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_WITH_DEBUG_INFO=OFF
    -DBUILD_WITH_STATIC_CRT=OFF
    -DBUILD_WITH_DYNAMIC_IPP=OFF
    -DBUILD_FAT_JAVA_LIB=OFF
    -DBUILD_ANDROID_SERVICE=OFF
    -DBUILD_CUDA_STUBS=OFF
    -DOPENCV_EXTRA_MODULES_PATH=
    -DINSTALL_CREATE_DISTRIB=OFF
    -DINSTALL_C_EXAMPLES=OFF
    -DINSTALL_TESTS=OFF
    -DINSTALL_PYTHON_EXAMPLES=OFF
    -DINSTALL_ANDROID_EXAMPLES=OFF
    -DINSTALL_TO_MANGLED_PATHS=OFF
    -DLIB_SUFFIX=
    -DENABLE_CCACHE=OFF
    -DENABLE_PRECOMPILED_HEADERS=OFF
    -DENABLE_SOLUTION_FOLDERS=OFF
    -DENABLE_PROFILING=OFF
    -DENABLE_COVERAGE=OFF
    -DHAVE_opencv_java=OFF
    -DENABLE_NOISY_WARNINGS=OFF
    -DOPENCV_WARNINGS_ARE_ERRORS=OFF
    -DENABLE_IMPL_COLLECTION=OFF
    -DENABLE_INSTRUMENTATION=OFF
    -DGENERATE_ABI_DESCRIPTOR=OFF
    -DDOWNLOAD_EXTERNAL_TEST_DATA=OFF
    -DBUILD_PACKAGE=OFF
    -DBUILD_PROTOBUF=OFF
    -DPROTOBUF_UPDATE_FILES=OFF
    -DOPENCV_DOC_INSTALL_PATH=
)

