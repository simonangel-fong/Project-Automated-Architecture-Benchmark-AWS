# postgres image contains psql, pg_isready
FROM postgres:16-alpine

WORKDIR /app

# copy sql scripts
COPY script ./script
# copy init shell script
COPY init.sh ./init.sh
RUN chmod +x ./init.sh

ENTRYPOINT ["./init.sh"]
