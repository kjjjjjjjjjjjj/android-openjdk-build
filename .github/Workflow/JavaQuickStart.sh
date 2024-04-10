name: Build OpenJDK for Android

on:
  workflow_dispatch:

jobs:
  build_android:
    strategy:
      matrix:
        arch: ["aarch32", "aarch64", "x86", "x86_64"]
      fail-fast: false

    name: "Build for Android ${{matrix.arch}}"
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: temurin

      - name: Install build dependencies
        run: |
          sudo apt update
          sudo apt -y install autoconf python3 python-is-python3 unzip zip \
          systemtap-sdt-dev libxtst-dev libasound2-dev libelf-dev libfontconfig1-dev \
          libx11-dev libxext-dev libxrandr-dev libxrender-dev libxtst-dev libxt-dev

      - name: Build with CI build script
        run: bash "ci_build_arch_${{matrix.arch}}.sh"

      - name: Upload JDK build output
        uses: actions/upload-artifact@v4
        with:
          name: "jdk17-${{matrix.arch}}"
          path: jdk17*.tar.xz

      - name: Upload JRE build output
        uses: actions/upload-artifact@v4
        with:
          name: "jre17-${{matrix.arch}}"
          path: jre17*.tar.xz

      - name: Upload JRE debuginfo build output
        uses: actions/upload-artifact@v4
        with:
          name: "jre17-debuginfo-${{matrix.arch}}"
          path: dizout

  pojav:
    needs: build_android
    runs-on: ubuntu-22.04

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Get JRE artifacts
        uses: actions/download-artifact@v4
        with:
          name: jre17-${{ matrix.arch }}
          path: pojav

      - name: Repack JRE
        run: bash "repackjre.sh" $GITHUB_WORKSPACE/pojav $GITHUB_WORKSPACE/pojav/jre17-pojav

      - name: Upload repacked JRE artifact
        uses: actions/upload-artifact@v4
        with:
          name: jre17-pojav
          path: pojav/jre17-pojav/*
