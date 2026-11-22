cmake_minimum_required(VERSION 3.21)

project(PhotoZipper VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(MSVC)
    add_compile_options(/utf-8 /W3)
endif()

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Network Concurrent)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(PhotoZipper WIN32
    src/main.cpp
    src/ThemeManager.h
    src/ImageTaskModel.h
    src/ImageTaskModel.cpp
    src/ImageMagickManager.h
    src/ImageMagickManager.cpp
    src/CompressionController.h
    src/CompressionController.cpp
    src/MemoryMonitor.h
    src/MemoryMonitor.cpp
    resources/app.rc
    resources/resources.qrc
)

qt_add_qml_module(PhotoZipper
    URI PhotoZipper
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/FloatingInput.qml
        qml/components/ModernCheckBox.qml
        qml/components/ModernComboBox.qml
        qml/components/SectionCard.qml
        qml/components/CompareView.qml
        qml/components/EngineUpdateDialog.qml
)

target_include_directories(PhotoZipper PRIVATE src)

target_link_libraries(PhotoZipper PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Concurrent
    psapi
)
