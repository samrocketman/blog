FROM ruby:2.7
EXPOSE 4000
ADD . /mnt
WORKDIR /mnt
RUN bundle install --jobs=3 --retry=3
CMD /bin/bash
