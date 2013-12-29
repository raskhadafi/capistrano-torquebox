# Capistrano::Torquebox

Torquebox support for Capistrano v3:

## Notes

**If you use this integration with capistrano-rails, please ensure that you have `capistrano-bundler >= 1.1.0`.**

## Installation

Add this line to your application's Gemfile:

    # Gemfile
    gem 'capistrano', '~> 3.0'
    gem 'capistrano-torquebox'

And then execute:

    $ bundle install

## Usage

Require in Capfile to use the default task:

    # Capfile
    require 'capistrano/torquebox'

And you should be good to go!
