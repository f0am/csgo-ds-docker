FROM centos:latest

ENV STEAMCMDDIR /home/csgo/steamcmd
RUN mkdir -p $STEAMCMDDIR
# RUN yum update
RUN yum upgrade -y
RUN yum install -y wget unzip
RUN adduser csgo
# RUN echo "admin" | passwd --stdin
RUN passwd csgo --stdin <<< 'admin'

# RUN firewall-cmd --zone=public --add-port=27015/tcp --permanent \
#     && firewall-cmd --zone=public --add-port=27015/udp --permanent \
#     && firewall-cmd --reload

RUN yum install glibc.i686 libstdc++.i686 -y

RUN su csgo
WORKDIR /home/csgo

RUN wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
RUN tar xf steamcmd_linux.tar.gz -C $STEAMCMDDIR

WORKDIR $STEAMCMDDIR
RUN ls -l
RUN df --output=avail -B 1 "$PWD" |tail -n 1

RUN ./steamcmd.sh +login anonymous +force_install_dir ./csgo_ds +app_update 740 validate +quit

WORKDIR /home/csgo

RUN wget https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git970-linux.tar.gz
RUN mkdir metamod
RUN tar xf mmsource-1.10.7-git970-linx.tar.gz -C ./metamod
RUN rsync -a ./metamod/ ./steamcmd/csgo_ds/addons/

RUN wget https://sm.alliedmods.net/smdrop/1.9/sourcemod-1.9.0-git6281-linux.tar.gz
RUN mkdir sourcemod
RUN tar xf sourcemod-1.9.0-git6281-linux.tar.gz  -C ./sourcemod
RUN rsync -a ./sourcemod/ ./steamcmd/csgo_ds/

# RUN wget https://github.com/splewis/csgo-pug-setup/releases/download/2.0.5/pugsetup_2.0.5.zip
# RUN unzip pugsetup_2.0.5.zip -d ./csgo_ds

RUN wget https://github.com/splewis/csgo-retakes/releases/download/v0.3.4/retakes_0.3.4.zip
RUN mkdir pug_plugin
RUN unzip pugsetup_2.0.5.zip -d ./pug_plugin
RUN rsync -a ./pug_plugin ./steamcmd/csgo_ds/

# Switch to user steam
# USER steam

ENV FPSMAX 300 \
    TICKRATE 128 \
    PORT 27015 \
    TV_PORT 27020 \
    MAXPLAYERS 12 \
    TOKEN 0 \
    RCONPW "yolo" \
    PW "" \
    STARTMAP "de_train" \
    REGION 0 \
    MAPGROUP "mg_active" \
    GAMETYPE 0 \
    GAMEMODE 1 \
    TOKEN "D769C4B2F3DAF0B2E7F0433346D9859A"


WORKDIR $STEAMAPPDIR

VOLUME $STEAMAPPDIR

# Set Entrypoint:
# 1. Update server
# 2. Start server
ENTRYPOINT ${STEAMCMDDIR}/steamcmd.sh \
    +login anonymous +force_install_dir ${STEAMAPPDIR} +app_update ${STEAMAPPID} +quit \
    && ${STEAMAPPDIR}/srcds_run \
    -game csgo -console -autoupdate -steam_dir ${STEAMCMDDIR} -steamcmd_script ${STEAMAPPDIR}/csgo_update.txt -usercon +fps_max $FPSMAX \
    -tickrate $TICKRATE -port $PORT -maxplayers_override $MAXPLAYERS +game_type $GAMETYPE +game_mode $GAMEMODE \
    +mapgroup $MAPGROUP +map $STARTMAP +sv_setsteamaccount $TOKEN +rcon_password $RCONPW +sv_password $PW +sv_region $REGION

# Expose ports
EXPOSE 27015 27020 27005 51840  