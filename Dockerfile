FROM alpine:latest

MAINTAINER Ramdhan Hidayat <madoen@users.noreply.github.com>
LABEL description Robot Framework in Docker.

# Setup volumes for input and output
VOLUME /opt/robotframework/reports
VOLUME /opt/robotframework/tests

# Setup X Window Virtual Framebuffer
ENV SCREEN_COLOUR_DEPTH 24
ENV SCREEN_HEIGHT 1080
ENV SCREEN_WIDTH 1920

# Set number of threads for parallel execution
# By default, no parallelisation
ENV ROBOT_THREADS 1

# Dependency versions
ENV CHROMIUM_VERSION 69.0
ENV FAKER_VERSION 4.2.0
ENV ICU_LIBS_VERSION 62.1
ENV FIREFOX_VERSION 62.0
ENV DBUS_VERSION 1.10.24
ENV GECKO_DRIVER_VERSION v0.23.0
ENV PABOT_VERSION 0.43
ENV PYTHON_PIP_VERSION 10.0
ENV REQUESTS_VERSION 0.4.7
ENV ROBOT_FRAMEWORK_VERSION 3.0.4
ENV SELENIUM_LIBRARY_VERSION 3.2.0
ENV XVFB_VERSION 1.20

# Add testing repository for Firefox
RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Upgrade system library
RUN apk update && \
  apk upgrade --available

# Install system dependencies
RUN apk add --no-cache \
  chromium-chromedriver>$CHROMIUM_VERSION \
  chromium>$CHROMIUM_VERSION \
  icu-libs@edge>$ICU_LIBS_VERSION \
  firefox@testing>$FIREFOX_VERSION ttf-freefont \
  dbus-x11>$DBUS_VERSION \
  py2-pip>$PYTHON_PIP_VERSION \
  xauth \
  xvfb>$XVFB_VERSION \
  which \
  wget

# Update pip version
RUN pip install --upgrade pip

# Install Robot Framework and Selenium Library
RUN pip install \
  robotframework==$ROBOT_FRAMEWORK_VERSION \
  robotframework-faker==$FAKER_VERSION \
  robotframework-pabot==$PABOT_VERSION \
  robotframework-requests==$REQUESTS_VERSION \
  robotframework-seleniumlibrary==$SELENIUM_LIBRARY_VERSION

# Download Gecko drivers directly from the GitHub repository
RUN wget -q "https://github.com/mozilla/geckodriver/releases/download/$GECKO_DRIVER_VERSION/geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz" \
  && tar xzf geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz \
  && mkdir -p /opt/robotframework/drivers/ \
  && mv geckodriver /opt/robotframework/drivers/geckodriver \
  && rm geckodriver-$GECKO_DRIVER_VERSION-linux64.tar.gz

# Prepare binaries to be executed
COPY bin/chromedriver.sh /opt/robotframework/bin/chromedriver
COPY bin/chromium-browser.sh /opt/robotframework/bin/chromium-browser
COPY bin/run-tests-in-virtual-screen.sh /opt/robotframework/bin/
COPY bin/xvfb-run.sh /usr/bin/xvfb-run

# FIXME: below is a workaround, as the path is ignored
RUN mv /usr/lib/chromium/chrome /usr/lib/chromium/chrome-original \
  && ln -sfv /opt/robotframework/bin/chromium-browser /usr/lib/chromium/chrome

# Update system path
ENV PATH=/opt/robotframework/bin:/opt/robotframework/drivers:$PATH

# Execute all robot tests
CMD ["run-tests-in-virtual-screen.sh"]
