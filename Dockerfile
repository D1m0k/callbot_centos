FROM centos:latest
LABEL maintainer="Dmitry Konovalov konovalov.d.s@gmail.com"
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
RUN cd /etc/yum.repos.d
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
RUN dnf install -y epel-release
RUN dnf -y install dnf-plugins-core
RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN dnf config-manager --set-enabled powertools 
RUN dnf install -y \
        glibc-langpack-ru \
        git \
        wget \
        net-tools \
        gcc \
        cpp \
        ncurses \
        ncurses-devel \
        libxml2 \
        libxml2-devel \
        sqlite \
        openssl-devel \
        newt-devel \
        libuuid-devel \
        gcc-c++ \
        sqlite-devel \
        psmisc \
        libtermcap-devel \
        libtiff-devel \
        gtk2-devel \
        libtool \
        libuuid-devel \
        subversion \
        kernel-devel \
        crontabs \
        cronie-anacron \
        mariadb \
        net-snmp-devel \
        xinetd \
        tar \
        jansson-devel \
        make \
        bzip2 \
        pjproject-devel \
        libsrtp-devel \
        gsm-devel \
        speex-devel \
        gettext \
        unixODBC \
        unixODBC-devel \
        libtool-ltdl \
        libtool-ltdl-devel \
        mariadb-connector-odbc \
        libedit-devel \
        gmime30-devel \
        speexdsp-devel \
        lua-devel \
        speex-devel \
        libedit \
        diffutils \
        python3 \
        python3-pip \
        nano \
        mc 
ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8
RUN pip3 install --no-cache-dir --upgrade pip \
&& pip3 install --no-cache-dir torch numpy pyst2 \
&& dnf clean all 
WORKDIR /usr/src 
RUN git clone -b certified/18.9-cert1 --depth 1 https://github.com/asterisk/asterisk.git asterisk 
WORKDIR /usr/src/asterisk
# Configure
RUN ls -l
RUN sh contrib/scripts/install_prereq install
RUN sh contrib/scripts/get_mp3_source.sh 
RUN ./configure 1> /dev/null 
RUN make -j$(nproc) menuselect.makeopts
RUN menuselect/menuselect \
  --disable BUILD_NATIVE \
  --enable format_mp3 \
  --enable cdr_csv \
  --enable chan_sip \
  --enable res_snmp \
  --enable res_http_websocket \
  --enable res_hep_pjsip \
  --enable res_hep_rtcp \
  --enable res_sorcery_astdb \
  --enable res_sorcery_config \
  --enable res_sorcery_memory \
  --enable res_sorcery_memory_cache \
  --disable res_pjproject \
  --enable res_rtp_asterisk \
  --enable res_ari \
  --enable res_ari_applications \
  --enable res_ari_asterisk \
  --enable res_ari_bridges \
  --enable res_ari_channels \
  --enable res_ari_device_states \
  --enable res_ari_endpoints \
  --enable res_ari_events \
  --enable res_ari_mailboxes \
  --enable res_ari_model \
  --enable res_ari_playbacks \
  --enable res_ari_recordings \
  --enable res_ari_sounds \
  --disable res_pjsip \
  --disable res_pjsip_acl \
  --disable res_pjsip_authenticator_digest \
  --disable res_pjsip_caller_id \
  --disable res_pjsip_config_wizard \
  --disable res_pjsip_dialog_info_body_generator \
  --disable res_pjsip_diversion \
  --disable res_pjsip_dlg_options \
  --disable res_pjsip_dtmf_info \
  --disable res_pjsip_empty_info \
  --disable res_pjsip_endpoint_identifier_anonymous \
  --disable res_pjsip_endpoint_identifier_ip \
  --disable res_pjsip_endpoint_identifier_user \
  --disable res_pjsip_exten_state \
  --disable res_pjsip_header_funcs \
  --disable res_pjsip_logger \
  --disable res_pjsip_messaging \
  --disable res_pjsip_mwi \
  --disable res_pjsip_mwi_body_generator \
  --disable res_pjsip_nat \
  --disable res_pjsip_notify \
  --disable res_pjsip_one_touch_record_info \
  --disable res_pjsip_outbound_authenticator_digest \
  --disable res_pjsip_outbound_publish \
  --disable res_pjsip_outbound_registration \
  --disable res_pjsip_path \
  --disable res_pjsip_pidf_body_generator \
  --disable res_pjsip_publish_asterisk \
  --disable res_pjsip_pubsub \
  --disable res_pjsip_refer \
  --disable res_pjsip_registrar \
  --disable res_pjsip_rfc3326 \
  --disable res_pjsip_sdp_rtp \
  --disable res_pjsip_send_to_voicemail \
  --disable res_pjsip_session \
  --disable res_pjsip_sips_contact \
  --disable res_pjsip_t38 \
  --disable res_pjsip_transport_websocket \
  --disable res_pjsip_xpidf_body_generator \
  --enable res_stasis \
  --enable res_stasis_answer \
  --enable res_stasis_device_state \
  --enable res_stasis_mailbox \
  --enable res_stasis_playback \
  --enable res_stasis_recording \
  --enable res_stasis_snoop \
  --enable res_stasis_test \
  --enable res_statsd \
  --enable res_timing_timerfd \
  --enable pbx_ael \
  menuselect.makeopts \
  && make -j$(nproc) 1> /dev/null \
  && make -j$(nproc) install 1> /dev/null \
  && make -j$(nproc) samples 1> /dev/null
WORKDIR /usr/src \
&& git clone https://github.com/alphacep/vosk-asterisk.git 
WORKDIR /usr/src/vosk-asterisk 
RUN mkdir /etc/asterisk/sip /etc/asterisk/dialplan /etc/asterisk/ael 
RUN ./bootstrap \
    && ./configure --with-asterisk=/usr/src/asterisk --prefix=/usr \
    && make \
    && make install \
    && cp -R /usr/etc/asterisk/ /etc/ \
    && sed -i -e 's/noload = chan_sip.so/require = chan_sip.so/' /etc/asterisk/modules.conf \
    && echo 'load = res_speech_vosk.so' >> /etc/asterisk/modules.conf \
    && echo 'noload = res_pjsip.so' >> /etc/asterisk/modules.conf \
    && echo 'noload = chan_pjsip.so' >> /etc/asterisk/modules.conf \
    && echo '#tryinclude sip/*.conf' >> /etc/asterisk/sip.conf \
    && echo '#tryinclude dialplan/*.conf' >> /etc/asterisk/extensions.conf \
    && echo '#tryinclude ael/*.conf' >> /etc/asterisk/extensions.ael \
    && echo 'HISTFILE=$HOME/.bash_history' >> ~/.bashrc \
    && echo 'set tabsize 4 \
             set tabstospaces \
             include /usr/share/nano/*' >> ~/.nanorc \
    # Update max number of open files.
    && sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk \
    # Set tty
    && sed -i 's/TTY=9/TTY=/g' /usr/sbin/safe_asterisk \
    # Create and configure asterisk for running asterisk user.
    && useradd -m asterisk -s /sbin/nologin \
    && chown -R asterisk:asterisk /var/run/asterisk \
                                  /etc/asterisk/ \
                                  /var/lib/asterisk \
                                  /var/log/asterisk \
                                  /var/spool/asterisk
# Running asterisk with user asterisk.
EXPOSE 5060/UDP
EXPOSE 5060/TCP
EXPOSE 10000-20000/UDP
USER asterisk
CMD /usr/sbin/asterisk -fvvvvv