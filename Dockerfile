FROM amberframework/amber:1.4.1

WORKDIR /app

COPY shard.* /app/
RUN shards install

COPY . /app

CMD amber watch
