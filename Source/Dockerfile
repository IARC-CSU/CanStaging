FROM ruby:2.5
LABEL maintainer="Morten Ervik <ervikm@iarc.fr>"
EXPOSE 80

RUN apt-get update -qq && apt-get install -y build-essential nano

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install --without development test

ADD . $APP_HOME

CMD ["ruby","WebService.rb"]
