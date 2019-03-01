FROM perl:5.24

MAINTAINER shunsuke maeda <duck8823@gmail.com>

RUN apt-get update && apt-get install -y git curl libio-socket-ssl-perl libnet-ssleay-perl

WORKDIR /workdir

COPY cpanfile .
RUN cpanm --installdeps .

COPY . .

RUN perl Build.PL && \
    ./Build

ENTRYPOINT ["./Build"]
CMD ["test"]
