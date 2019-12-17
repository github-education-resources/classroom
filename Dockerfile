FROM debian:jessie-slim

RUN apt-get -y update && \
    apt-get -y install netcat-traditional && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY . /data/classroom
WORKDIR /data/classroom

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8080/ || exit 1
  
EXPOSE 8080
ENTRYPOINT ["bash", "-c", "while true ; do  echo -e \"HTTP/1.1 200 OK\nContent-Type: text/plain; charset=utf-8\n\nWelcome to Moda! Your app (classroom) is set up correctly 🍦\" | nc -l -p 8080 -q 1 ; done"]
