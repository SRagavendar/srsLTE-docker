FROM ubuntu:18.04
MAINTAINER SRagavendar 
ENV DEBIAN_FRONTEND nointeractive
RUN apt-get update
RUN apt-get -yq dist-upgrade
RUN apt-get -yq install libboost-all-dev libusb-1.0-0-dev doxygen python3-docutils python3-mako python3-numpy python3-requests python3-ruamel.yaml python3-setuptools cmake build-essential

# Dependencies for UHD image downloader script
RUN apt-get -yq install libboost-all-dev libusb-1.0-0-dev doxygen python3-docutils python3-mako python3-numpy python3-requests python3-ruamel.yaml python3-setuptools cmake build-essential

# Fetching the uhd 3.15.000 driver for our USRP SDR card 
RUN wget https://files.ettus.com/binaries/uhd/uhd_003.015.000.000-release/uhd_3.15.0.0-release.tar.gz && tar xvzf uhd_3.15.0.0-release.tar.gz && cd uhd_3.15.0.0-release && mkdir build && cd build && cmake ../ && make && make install && ldconfig && python /usr/local/lib/uhd/utils/uhd_images_downloader.py

# Dependencies for srsLTE
RUN apt-get -yq install cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev

# Volk for GNU Radio
WORKDIR ~
RUN wget http://libvolk.org/releases/volk-2.4.0.tar.xz
RUN tar xvzf volk-2.4.0.tar.xz && cd ~/volk-2.4.0 && mkdir build && cd build && cmake ../ && make install
RUN ldconfig && volk_profile

# Fetch the package for srsLTE
WORKDIR ~
RUN git clone https://github.com/srsLTE/srsLTE.git
WORKDIR ~/srsLTE/
RUN mkdir build && cd build && cmake ../ && make && make test && sudo make install && sudo srslte_install_configs.sh user

# Configuration
WORKDIR ~/srsLTE/build/srsenb/src
RUN cp ../../../srsenb/*.example .
RUN mv sib.conf.example sib.conf
RUN mv rr.conf.example rr.conf  
RUN mv enb.conf.example enb.conf  
RUN mv drb.conf.example drb.conf 
RUN sed -i "s/0x19B/0xe00/g" enb.conf
RUN sed -i "s/phy_cell_id = 1/phy_cell_id = 2/g" enb.conf
RUN sed -i "s/mcc = 001/mcc = 208/g" enb.conf
RUN sed -i "s/mnc = 01/mnc = 92/g" enb.conf
RUN sed -i "s/dl_earfcn = 3400/dl_earfcn = 1800/g" enb.conf
RUN sed -i "s/tx_gain = 70/tx_gain = 90/g" enb.conf
RUN sed -i "s/rx_gain = 50/rx_gain = 120/g" enb.conf
RUN sed -i "s/n_prb = 25/n_prb = 25/g" enb.conf

ENTRYPOINT ~/srsLTE/build/srsenb/src/srsenb --enb.name=srstid01 enb.conf