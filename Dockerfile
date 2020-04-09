FROM ruby:2.6

WORKDIR /app
COPY . .
RUN gem install --no-document bundler \
    && bundle config --local frozen true \
    && bundle install

ENTRYPOINT ["bundle", "exec", "functions-framework"]
CMD ["--target", "lock_door", "--source", "locker.rb"]
