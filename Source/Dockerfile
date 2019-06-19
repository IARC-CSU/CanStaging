FROM ruby:2.5
LABEL maintainer="Morten Ervik <ervikm@iarc.fr>"
EXPOSE 80

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

COPY . .

CMD ["./WebService.rb"]
