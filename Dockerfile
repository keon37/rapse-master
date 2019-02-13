FROM python:3.6

RUN apt-get update

# R 
RUN apt-get install -y r-base libmariadbclient-dev libmariadb-client-lgpl-dev libssl-dev libgirepository1.0-dev

COPY ./app/r/install_packages.R /tmp/
RUN Rscript /tmp/install_packages.R


# python
COPY requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt


# for docker host ip
RUN apt-get install -y iputils-ping iproute2 \
  && rm -rf /var/lib/apt/lists/*


# ARG CACHEBUST=1