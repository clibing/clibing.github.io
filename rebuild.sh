#!/usr/bin/env bash

# env
BLOG_HOME="/home/blog/clibing.github.io"

# kill jekyll
echo -e "`date '+%Y-%m-%d %H:%M:%S'` kill jekyll"
pkill -f jekyll

# git pull
cd ${BLOG_HOME}
git pull

/usr/local/rvm/gems/ruby-2.3.0/bin/jekyll serve -H 0.0.0.0 -P 8080 --detach



