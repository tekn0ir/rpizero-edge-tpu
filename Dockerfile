FROM balenalib/raspberry-pi-debian:stretch-build

RUN [ "cross-build-start" ]

#labeling
LABEL mantainer="Anders Åslund <teknoir@teknoir.se>" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="rpizero-edge-tpu" \
    org.label-schema.description="Docker running Raspbian including Coral Edge-TPU libraries" \
    org.label-schema.url="https://www.teknoir.se" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/tekn0ir" \
    org.label-schema.vendor="Anders Åslund" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

ENV READTHEDOCS True

#install libraries for camera
RUN apt-get update && \
    apt-get install -y --no-install-recommends --allow-downgrades \
    build-essential wget feh pkg-config libjpeg-dev zlib1g-dev \
#    libraspberrypi-bin \
#    libraspberrypi0 \
#    libraspberrypi-dev \
#    libraspberrypi-doc \
    libraspberrypi-bin=1.20180328-1~nokernel1 \
    libraspberrypi0=1.20180328-1~nokernel1 \
    libraspberrypi-dev=1.20180328-1~nokernel1 \
    libraspberrypi-doc=1.20180328-1~nokernel1 \
    libfreetype6-dev libxml2 libopenjp2-7 \
    libatlas-base-dev libjasper-dev libqtgui4 libqt4-test \
    python3-dev python3-pip python3-setuptools python3-wheel python3-numpy python3-pil python3-matplotlib python3-zmq

#python libraries
RUN python3 -m pip install supervisor \
    && python3 -m pip install picamera python-periphery imutils

#installing edge-tpu library
WORKDIR /opt
RUN wget https://github.com/google-coral/edgetpu-platforms/releases/download/v1.9.2/edgetpu_api_1.9.2.tar.gz -O edgetpu_api.tar.gz --trust-server-names \
    && tar xzf edgetpu_api.tar.gz \
    && rm edgetpu_api.tar.gz \
    && cd /opt/edgetpu_api/ \
    && chmod +x install.sh \
    && sed -i 's/MODEL=\$(cat \/proc\/device-tree\/model)/MODEL="Raspberry Pi Zero W Rev 1\.1"/g' install.sh \
    && sed -i 's/read USE_MAX_FREQ/USE_MAX_FREQ="No"/g' install.sh \
    && cat install.sh \
    && bash install.sh -y

#loading pretrained models
WORKDIR /app
RUN mkdir test_data \
    && wget -P test_data/ https://storage.googleapis.com/cloud-iot-edge-pretrained-models/canned_models/mobilenet_v2_1.0_224_quant_edgetpu.tflite \
    && wget -P test_data/ http://storage.googleapis.com/cloud-iot-edge-pretrained-models/canned_models/imagenet_labels.txt
COPY app.py ./

#set stop signal
STOPSIGNAL SIGTERM

RUN usermod -a -G video root

#stop processing ARM emulation (comment out next line if built on Raspberry)
RUN [ "cross-build-end" ]
CMD ["python3", "app.py"]
