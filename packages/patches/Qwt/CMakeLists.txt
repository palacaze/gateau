cmake_minimum_required(VERSION 3.15)

project(qwt
    VERSION 6.2.0
    DESCRIPTION "Qwt"
    HOMEPAGE_URL "https://www.qwt.sourceforge.net"
    LANGUAGES CXX
)

option(QWT_WITH_PLOT "Enable support for QwtPlot" ON)
option(QWT_WITH_OPENGL "Enable support for OpenGL" ON)
option(QWT_WITH_SVG "Enable support for SVG" OFF)
option(QWT_WITH_WIDGETS "Enable support for additonal Widgets" ON)
option(QWT_WITH_POLAR "Enable support for additonal QwtPolar" OFF)

set(qt_required Core Gui Widgets PrintSupport Concurrent)

find_package(Qt6 COMPONENTS ${qt_required} OPTIONAL_COMPONENTS Svg OpenGL OpenGLWidgets)
set(qt_ver ${Qt6_VERSION_MAJOR})

if (NOT Qt6_FOUND)
    find_package(Qt5 5.15 COMPONENTS ${qt_required} OPTIONAL_COMPONENTS Svg OpenGL REQUIRED)
    set(qt_ver ${Qt5_VERSION_MAJOR})
endif()

set(qwt_libname qwt${PROJECT_VERSION_MAJOR}-qt${qt_ver})


add_library(Qwt)
add_library(Qwt::Qwt ALIAS Qwt)

target_compile_definitions(Qwt
    PUBLIC
        $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,SHARED>:QT_DLL;QWT_DLL>
    PRIVATE
        QWT_MOC_INCLUDE
        $<$<STREQUAL:$<TARGET_PROPERTY:TYPE>, SHARED>:QWT_MAKEDLL>
)

set_target_properties(Qwt PROPERTIES
    AUTOMOC ON
    AUTORCC ON
    OUTPUT_NAME ${qwt_libname}
    $<$<CONFIG:Release>:C_VISIBILITY_PRESET hidden>
    $<$<CONFIG:Release>:CXX_VISIBILITY_PRESET hidden>
    $<$<CONFIG:Release>:VISIBILITY_INLINES_HIDDEN 1>
)

target_include_directories(Qwt PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include/${qwt_libname}>
)

target_link_libraries(Qwt PUBLIC
    Qt::Core
    Qt::Gui
    Qt::Widgets
    Qt::PrintSupport
    Qt::Concurrent
)

target_sources(Qwt PRIVATE
    src/qwt.h
    src/qwt_abstract_scale_draw.h
    src/qwt_bezier.h
    src/qwt_clipper.h
    src/qwt_color_map.h
    src/qwt_column_symbol.h
    src/qwt_date.h
    src/qwt_date_scale_draw.h
    src/qwt_date_scale_engine.h
    src/qwt_dyngrid_layout.h
    src/qwt_global.h
    src/qwt_graphic.h
    src/qwt_interval.h
    src/qwt_interval_symbol.h
    src/qwt_math.h
    src/qwt_magnifier.h
    src/qwt_null_paintdevice.h
    src/qwt_painter.h
    src/qwt_painter_command.h
    src/qwt_panner.h
    src/qwt_picker.h
    src/qwt_picker_machine.h
    src/qwt_pixel_matrix.h
    src/qwt_point_3d.h
    src/qwt_point_polar.h
    src/qwt_round_scale_draw.h
    src/qwt_scale_div.h
    src/qwt_scale_draw.h
    src/qwt_scale_engine.h
    src/qwt_scale_map.h
    src/qwt_spline.h
    src/qwt_spline_basis.h
    src/qwt_spline_parametrization.h
    src/qwt_spline_local.h
    src/qwt_spline_cubic.h
    src/qwt_spline_pleasing.h
    src/qwt_spline_polynomial.h
    src/qwt_symbol.h
    src/qwt_system_clock.h
    src/qwt_text_engine.h
    src/qwt_text_label.h
    src/qwt_text.h
    src/qwt_transform.h
    src/qwt_widget_overlay.h
    src/qwt.cpp
    src/qwt_abstract_scale_draw.cpp
    src/qwt_bezier.cpp
    src/qwt_clipper.cpp
    src/qwt_color_map.cpp
    src/qwt_column_symbol.cpp
    src/qwt_date.cpp
    src/qwt_date_scale_draw.cpp
    src/qwt_date_scale_engine.cpp
    src/qwt_dyngrid_layout.cpp
    src/qwt_event_pattern.cpp
    src/qwt_graphic.cpp
    src/qwt_interval.cpp
    src/qwt_interval_symbol.cpp
    src/qwt_math.cpp
    src/qwt_magnifier.cpp
    src/qwt_null_paintdevice.cpp
    src/qwt_painter.cpp
    src/qwt_painter_command.cpp
    src/qwt_panner.cpp
    src/qwt_picker.cpp
    src/qwt_picker_machine.cpp
    src/qwt_pixel_matrix.cpp
    src/qwt_point_3d.cpp
    src/qwt_point_polar.cpp
    src/qwt_round_scale_draw.cpp
    src/qwt_scale_div.cpp
    src/qwt_scale_draw.cpp
    src/qwt_scale_map.cpp
    src/qwt_scale_engine.cpp
    src/qwt_spline.cpp
    src/qwt_spline_basis.cpp
    src/qwt_spline_parametrization.cpp
    src/qwt_spline_local.cpp
    src/qwt_spline_cubic.cpp
    src/qwt_spline_pleasing.cpp
    src/qwt_spline_polynomial.cpp
    src/qwt_symbol.cpp
    src/qwt_system_clock.cpp
    src/qwt_text_engine.cpp
    src/qwt_text_label.cpp
    src/qwt_text.cpp
    src/qwt_transform.cpp
    src/qwt_widget_overlay.cpp
)

if (QWT_WITH_PLOT)
    target_sources(Qwt PRIVATE
        src/qwt_axis.h
        src/qwt_axis_id.h
        src/qwt_curve_fitter.h
        src/qwt_spline_curve_fitter.h
        src/qwt_weeding_curve_fitter.h
        src/qwt_event_pattern.h
        src/qwt_abstract_legend.h
        src/qwt_legend.h
        src/qwt_legend_data.h
        src/qwt_legend_label.h
        src/qwt_plot.h
        src/qwt_plot_renderer.h
        src/qwt_plot_curve.h
        src/qwt_plot_dict.h
        src/qwt_plot_directpainter.h
        src/qwt_plot_graphicitem.h
        src/qwt_plot_grid.h
        src/qwt_plot_histogram.h
        src/qwt_plot_item.h
        src/qwt_plot_abstract_barchart.h
        src/qwt_plot_barchart.h
        src/qwt_plot_multi_barchart.h
        src/qwt_plot_intervalcurve.h
        src/qwt_plot_tradingcurve.h
        src/qwt_plot_layout.h
        src/qwt_plot_marker.h
        src/qwt_plot_zoneitem.h
        src/qwt_plot_textlabel.h
        src/qwt_plot_rasteritem.h
        src/qwt_plot_spectrogram.h
        src/qwt_plot_spectrocurve.h
        src/qwt_plot_scaleitem.h
        src/qwt_plot_legenditem.h
        src/qwt_plot_seriesitem.h
        src/qwt_plot_shapeitem.h
        src/qwt_plot_vectorfield.h
        src/qwt_plot_abstract_canvas.h
        src/qwt_plot_canvas.h
        src/qwt_plot_panner.h
        src/qwt_plot_picker.h
        src/qwt_plot_zoomer.h
        src/qwt_plot_magnifier.h
        src/qwt_plot_rescaler.h
        src/qwt_point_mapper.h
        src/qwt_raster_data.h
        src/qwt_matrix_raster_data.h
        src/qwt_vectorfield_symbol.h
        src/qwt_sampling_thread.h
        src/qwt_samples.h
        src/qwt_series_data.h
        src/qwt_series_store.h
        src/qwt_point_data.h
        src/qwt_scale_widget.h
        src/qwt_curve_fitter.cpp
        src/qwt_spline_curve_fitter.cpp
        src/qwt_weeding_curve_fitter.cpp
        src/qwt_abstract_legend.cpp
        src/qwt_legend.cpp
        src/qwt_legend_data.cpp
        src/qwt_legend_label.cpp
        src/qwt_plot.cpp
        src/qwt_plot_renderer.cpp
        src/qwt_plot_axis.cpp
        src/qwt_plot_curve.cpp
        src/qwt_plot_dict.cpp
        src/qwt_plot_directpainter.cpp
        src/qwt_plot_graphicitem.cpp
        src/qwt_plot_grid.cpp
        src/qwt_plot_histogram.cpp
        src/qwt_plot_item.cpp
        src/qwt_plot_abstract_barchart.cpp
        src/qwt_plot_barchart.cpp
        src/qwt_plot_multi_barchart.cpp
        src/qwt_plot_intervalcurve.cpp
        src/qwt_plot_zoneitem.cpp
        src/qwt_plot_tradingcurve.cpp
        src/qwt_plot_spectrogram.cpp
        src/qwt_plot_spectrocurve.cpp
        src/qwt_plot_scaleitem.cpp
        src/qwt_plot_legenditem.cpp
        src/qwt_plot_seriesitem.cpp
        src/qwt_plot_shapeitem.cpp
        src/qwt_plot_vectorfield.cpp
        src/qwt_plot_marker.cpp
        src/qwt_plot_textlabel.cpp
        src/qwt_plot_layout.cpp
        src/qwt_plot_abstract_canvas.cpp
        src/qwt_plot_canvas.cpp
        src/qwt_plot_panner.cpp
        src/qwt_plot_rasteritem.cpp
        src/qwt_plot_picker.cpp
        src/qwt_plot_zoomer.cpp
        src/qwt_plot_magnifier.cpp
        src/qwt_plot_rescaler.cpp
        src/qwt_point_mapper.cpp
        src/qwt_raster_data.cpp
        src/qwt_matrix_raster_data.cpp
        src/qwt_vectorfield_symbol.cpp
        src/qwt_sampling_thread.cpp
        src/qwt_series_data.cpp
        src/qwt_point_data.cpp
        src/qwt_scale_widget.cpp
    )
endif()

if (TARGET Qt::Svg AND QWT_WITH_SVG)
    target_sources(Qwt PRIVATE
        src/qwt_plot_svgitem.h
        src/qwt_plot_svgitem.cpp
    )

    target_link_libraries(Qwt PUBLIC
        Qt::Svg
    )

    list(APPEND qt_required Svg)
else()
    target_compile_definitions(Qwt PUBLIC QWT_NO_SVG)
endif()

if (TARGET Qt::OpenGL AND QWT_WITH_OPENGL)
    if (qt_ver GREATER_EQUAL 6)
        if (TARGET Qt::OpenGLWidgets)
            target_sources(Qwt PRIVATE
                src/qwt_plot_opengl_canvas.h
                src/qwt_plot_opengl_canvas.cpp
            )

            target_link_libraries(Qwt PRIVATE Qt::OpenGL Qt::OpenGLWidgets)

            list(APPEND qt_required OpenGL OpenGLWidgets)
        else()
            target_compile_definitions(Qwt PUBLIC QWT_NO_OPENGL)
        endif()
    else()
        target_sources(Qwt PRIVATE
            src/qwt_plot_glcanvas.h
            src/qwt_plot_glcanvas.cpp
            src/qwt_plot_opengl_canvas.h
            src/qwt_plot_opengl_canvas.cpp
        )
        target_link_libraries(Qwt PRIVATE Qt::OpenGL)

        list(APPEND qt_required OpenGL)
    endif()
else()
    target_compile_definitions(Qwt PUBLIC QWT_NO_OPENGL)
endif()

if (QWT_WITH_POLAR)
    target_sources(Qwt PRIVATE
        src/qwt_polar.h
        src/qwt_polar_canvas.h
        src/qwt_polar_curve.h
        src/qwt_polar_fitter.h
        src/qwt_polar_grid.h
        src/qwt_polar_itemdict.h
        src/qwt_polar_item.h
        src/qwt_polar_layout.h
        src/qwt_polar_magnifier.h
        src/qwt_polar_marker.h
        src/qwt_polar_panner.h
        src/qwt_polar_picker.h
        src/qwt_polar_plot.h
        src/qwt_polar_renderer.h
        src/qwt_polar_spectrogram.h
        src/qwt_polar_canvas.cpp
        src/qwt_polar_curve.cpp
        src/qwt_polar_fitter.cpp
        src/qwt_polar_grid.cpp
        src/qwt_polar_item.cpp
        src/qwt_polar_itemdict.cpp
        src/qwt_polar_layout.cpp
        src/qwt_polar_magnifier.cpp
        src/qwt_polar_marker.cpp
        src/qwt_polar_panner.cpp
        src/qwt_polar_picker.cpp
        src/qwt_polar_plot.cpp
        src/qwt_polar_renderer.cpp
        src/qwt_polar_spectrogram.cpp
    )
endif()

if (QWT_WITH_WIDGETS)
    target_sources(Qwt PRIVATE
        src/qwt_abstract_slider.h
        src/qwt_abstract_scale.h
        src/qwt_arrow_button.h
        src/qwt_analog_clock.h
        src/qwt_compass.h
        src/qwt_compass_rose.h
        src/qwt_counter.h
        src/qwt_dial.h
        src/qwt_dial_needle.h
        src/qwt_knob.h
        src/qwt_slider.h
        src/qwt_thermo.h
        src/qwt_wheel.h
        src/qwt_abstract_slider.cpp
        src/qwt_abstract_scale.cpp
        src/qwt_arrow_button.cpp
        src/qwt_analog_clock.cpp
        src/qwt_compass.cpp
        src/qwt_compass_rose.cpp
        src/qwt_counter.cpp
        src/qwt_dial.cpp
        src/qwt_dial_needle.cpp
        src/qwt_knob.cpp
        src/qwt_slider.cpp
        src/qwt_thermo.cpp
        src/qwt_wheel.cpp
    )
endif()

# Installation

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(
    TARGETS Qwt
    EXPORT QwtTargets
    RUNTIME
        DESTINATION "${CMAKE_INSTALL_BINDIR}"
        COMPONENT QwtRuntime
    LIBRARY
        DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        COMPONENT QwtRuntime
        NAMELINK_COMPONENT QwtDevel
    ARCHIVE
        DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        COMPONENT QwtDevel
    # INCLUDES
        # COMPONENT QwtDevel
    RESOURCE
        DESTINATION "${CMAKE_INSTALL_DATADIR}/Qwt"
        EXCLUDE_FROM_ALL
)

get_target_property(qwt_headers Qwt SOURCES)
list(FILTER qwt_headers INCLUDE REGEX ".*\\.h")

install(
    FILES ${qwt_headers}
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${qwt_libname}"
    COMPONENT QwtDevel
)

install(
    EXPORT QwtTargets
    FILE QwtTargets.cmake
    NAMESPACE Qwt::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/Qwt"
    COMPONENT QwtDevel
)

# setup Qt dependency check
if (qt_ver GREATER_EQUAL 6)
    set(Qwt_QT_DEPENDENCY "Qt${qt_ver} COMPONENTS ${qt_required}")
else()
    set(Qwt_QT_DEPENDENCY "Qt5 5.15 COMPONENTS ${qt_required}")
endif()

configure_package_config_file(
    "${PROJECT_SOURCE_DIR}/QwtConfig.cmake.in"
    "${PROJECT_BINARY_DIR}/QwtConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/Qwt"
)

write_basic_package_version_file(
    "${PROJECT_BINARY_DIR}/QwtConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        "${PROJECT_BINARY_DIR}/QwtConfig.cmake"
        "${PROJECT_BINARY_DIR}/QwtConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/Qwt"
    COMPONENT QwtDevel
)

export(
    TARGETS Qwt
    NAMESPACE Qwt::
    FILE QwtTargets.cmake
)

