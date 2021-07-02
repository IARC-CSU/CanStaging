FROM ruby:3.0
LABEL maintainer="Morten Ervik <ervikm@iarc.fr>"
EXPOSE 4567

RUN apt-get update -qq && apt-get install -y build-essential nano

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Source/Gemfile* $APP_HOME/
RUN gem install bundler
# RUN bundle config set without 'development test'
RUN bundle install

ADD Source/. $APP_HOME

# CMD ["ruby","WebService.rb"]
# Make sure we load ruby with the gems specified in the Gemfile...
CMD ["bundle", "exec", "ruby", "WebService.rb"]
