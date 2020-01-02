FROM taojy123/vlang
RUN mkdir /test/semver/
WORKDIR /test/semver/
COPY . .
RUN v test .
