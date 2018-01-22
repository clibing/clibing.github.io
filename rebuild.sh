#!/usr/bin/env bash

# env
BLOG_HOME="/home/blog/clibing.github.io"
GIT_PULL_LOG="/tmp/git.pull.log"

# git pull
cd ${BLOG_HOME}
git pull > ${GIT_PULL_LOG}
GIT_STATUS=`cat /tmp/git.pull.log | grep 'Already' | awk '{print $1" "}'`
if [ "${GIT_STATUS}" = 'Already ' ]; then
    echo -e "`date '+%Y-%m-%d %H:%M:%S'` git none update">>${GIT_PULL_LOG}
    exit 1
fi

# kill jekyll
echo -e "`date '+%Y-%m-%d %H:%M:%S'` kill jekyll">>${GIT_PULL_LOG}
ps -aef|grep jekyll | grep 'ruby' | awk '{print $2}' | xargs kill -9 >>${GIT_PULL_LOG}

# start serve
rvm requirements
rvm install 2.3.0 
rvm use 2.3.0 --default 
gem install bundler 
bundle install

/usr/local/rvm/gems/ruby-2.3.0/bin/jekyll serve -H 0.0.0.0 -P 8080 --detach >>${GIT_PULL_LOG}
