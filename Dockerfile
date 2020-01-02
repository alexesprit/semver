FROM taojy123/vlang
RUN mkdir /home/semver/
WORKDIR /home/semver/
COPY . .
RUN v test .
