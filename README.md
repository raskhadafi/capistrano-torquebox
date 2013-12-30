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

    $ bundle

Or install it yourself as:

    $ gem install capistrano-torquebox

## Usage

Require in Capfile to use the default task:

    # Capfile
    require 'capistrano/torquebox'

And you should be good to go!

## Contributing

1. Fork it ( http://github.com/raskhadafi/capistrano-torquebox/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request