FROM ruby:2.5
LABEL maintainer="Morten Ervik <ervikm@iarc.fr>"
EXPOSE 80

RUN apt-get update -qq && apt-get install -y build-essential nano

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN gem install bundler
# RUN bundle config set without 'development test'
RUN bundle install

ADD . $APP_HOME

# CMD ["ruby","WebService.rb"]
CMD ["bundle", "exec", "ruby", "WebService.rb"]