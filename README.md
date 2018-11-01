<a href="https://postmarkapp.com">
    <img src="postmark.png" alt="Postmark Logo" title="Postmark" width="120" height="120" align="right">
</a>

# Postmark Ruby Gem
[![Build Status](https://travis-ci.org/wildbit/postmark-gem.svg?branch=master)](https://travis-ci.org/wildbit/postmark-gem) [![Code Climate](https://codeclimate.com/github/wildbit/postmark-gem/badges/gpa.svg)](https://codeclimate.com/github/wildbit/postmark-gem)
[![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](http://www.opensource.org/licenses/MIT)
[![Gem Version](https://badge.fury.io/rb/postmark.svg)](https://badge.fury.io/rb/postmark)

Postmark allows you to send your emails with high delivery rates. It also includes detailed statistics. In addition, Postmark can parse incoming emails which are forwarded back to your application.

This gem is the official wrapper for the [Postmark HTTP API](http://postmarkapp.com). 

## Usage

Please see the [wiki](https://github.com/wildbit/postmark-gem/wiki) for detailed instructions about sending email, using the bounce api and other Postmark API features.
For details about Postmark API in general, please check out [Postmark developer docs](https://postmarkapp.com/developer).

## Requirements

You will need a Postmark account, server and sender signature (or verified domain) set up to use it. For details about setup, check out [wiki pages](https://github.com/wildbit/postmark-gem/wiki/Getting-Started).

If you plan using the library in a Rails project, check out the [postmark-rails](https://github.com/wildbit/postmark-rails/) gem, which
is meant to integrate with ActionMailer. The plugin will try to use ActiveSupport JSon if it is already included. If not,
it will attempt to use the built-in Ruby JSon library.

You can also explicitly specify which one to be used, using following code:

``` ruby
Postmark.response_parser_class = :Json # :ActiveSupport or :Yajl are also supported.
```

## Installation

You can use the library with or without a Bundler.

With Bundler:

``` ruby
gem 'postmark'
```

Without Bundler:

``` bash
gem install postmark
```

## Note on Patches/Pull Requests

See [CONTRIBUTING.md](CONTRIBUTING.md) file for details.

## Issues & Comments

Feel free to contact us if you encounter any issues with the library or Postmark API. 
Please leave all comments, bugs, requests and issues on the Issues page.  

## License

The Postmark Ruby library is licensed under the [MIT](http://www.opensource.org/licenses/mit-license.php) license. 
Refer to the [LICENSE](https://github.com/wildbit/postmark-gem/blob/master/LICENSE) file for more information.

## Copyright

Copyright © 2018 Wildbit LLC. 
