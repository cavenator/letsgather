#LetsGather image with sqlite db.  This is more for self-contained development demos
FROM ubuntu:14.04
RUN apt-get update -q
RUN apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev ruby1.9.1 ruby1.9.1-dev libopenssl-ruby1.9.1 rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 bundler libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libgdbm-dev libncurses5-dev automake libtool bison libffi-dev vim

RUN mkdir -p /app/letsgather
ADD . /app/letsgather/
WORKDIR /app/letsgather
RUN bundle install

RUN bundle exec rake db:create
RUN bundle exec rake db:migrate

EXPOSE 5000
CMD ["start"]
ENTRYPOINT ["foreman"]
