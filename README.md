# Postmark Gem

This gem is an official wrapper for [Postmark HTTP API](http://postmarkapp.com). Use it to send emails and retrieve info about bounces.

## Install

``` bash
gem install postmark
```

In addition to the `postmark` gem you also need to install `mail` or `tmail` gem. Pick the one you like most:

``` bash
gem install mail
# - or -
gem install tmail
```

## Mail Example

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

# Use json gem to parse response
Postmark.response_parser_class = :Json

# Put your Postmark api key here
api_key = 'your-postmark-api-key'

# Plain text message
message = Mail.new do
  from           'sheldon@bigbangtheory.com'
  to             'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject        'Re: Come on, Sheldon. It will be fun.'
  body           'That\'s what you said about the Green Lantern movie. You' \
                 'were 114 minutes of wrong.'

  delivery_method Mail::Postmark, :api_key => api_key
end

message.deliver

# HTML message
message = Mail.new do
  from           'sheldon@bigbangtheory.com'
  to             'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject        'Re: What, to you, is a large crowd?'

  content_type   'text/html; charset=UTF-8'
  body           '<p>Any group big enough to trample me to death. General ' \
                 'rule of thumb is 36 adults or 70 children.</p>'

  delivery_method Mail::Postmark, :api_key => api_key
end

message.deliver

# Multipart message
message = Mail.new do
  from           'sheldon@bigbangtheory.com'
  to             'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject        'Re: Anything Can Happen Thursday'
  delivery_method Mail::Postmark, :api_key => api_key

  text_part do
    body         'Apparently the news didn\'t reach my digestive system,' \
                 ' which when startled has it\'s own version of "Anything' \
                 ' Can Happen Thursday"'
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body         '<p>Apparently the news didn&rsquo;t reach my digestive ' \
                 'system, which when startled has it&rsquo;s own version ' \
                 'of &ldquo;Anything Can Happen Thursday&rdquo;</p>'
  end
end

message.deliver
```

## TMail Example

``` ruby
require 'rubygems'
require 'postmark'
require 'tmail'
require 'json'

Postmark.api_key = "your-api-key"

# Make sure you have a sender signature for every From email you specify.
# From can also accept array of addresses.

message              = TMail::Mail.new
message.from         = "leonard@bigbangtheory.com"
message.to           = "Sheldon Cooper <sheldon@bigbangtheory.com>"
message.subject      = "Hi Sheldon!"
message.content_type = "text/html"
message.body         = "Hello my friend!"

# You can set customer headers if you like:
message["CUSTOM-HEADER"] = "my custom header value"

# Added a tag:
message.tag = "my-tracking-tag"

# Add attachments:
message.postmark_attachments = [File.open("/path"), File.open("/path")]

# Add attachments with content generated on the fly:
message.postmark_attachments = [{
  "Name" => "September 2011.pdf",
  "Content" => [pdf_content].pack("m"),
  "ContentType" => "application/pdf"
}]

# Or specify a reply-to address (can also be an array of addresses):
message.reply_to = "penny@bigbangtheory.com"

Postmark.send_through_postmark(message)
```

## Other API Features

You can retrieve various information about your server state using the [Public
bounces API](http://developer.postmarkapp.com/bounces).

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

Postmark.response_parser_class = :Json
Postmark.api_key = 'your-postmark-api-key'

# Delivery stats
Postmark.delivery_stats
# => {"InactiveMails"=>1, "Bounces"=>[{"Name"=>"All", "Count"=>1}, {"Type"=>"HardBounce", "Name"=>"Hard bounce", "Count"=>1}]}

# Get bounces information: (array of bounce objects)
Postmark::Bounce.all
# => [#<Postmark::Bounce:0x007ff09c04ae18 @id=580516117, @email="sheldon@bigbangtheory.com", @bounced_at=2012-10-21 00:01:56 +0800, @type="HardBounce", @name=nil, @details="smtp;550 5.1.1 The email account that you tried to reach does not exist. Please try double-checking the recipient's email address for typos or unnecessary spaces. Learn more at http://support.google.com/mail/bin/answer.py?answer=6596 c13si5382730vcw.23", @tag=nil, @dump_available=false, @inactive=true, @can_activate=true, @message_id="876d40fe-ab2a-4925-9d6f-8d5e4f4926f5", @subject="Re: What, to you, is a large crowd?">]

# Find specific bounce by id:
bounce = Postmark::Bounce.find(5)
# => #<Postmark::Bounce:0x007ff09c04ae18 @id=580516117, @email="sheldon@bigbangtheory.com", @bounced_at=2012-10-21 00:01:56 +0800, @type="HardBounce", @name=nil, @details="smtp;550 5.1.1 The email account that you tried to reach does not exist. Please try double-checking the recipient's email address for typos or unnecessary spaces. Learn more at http://support.google.com/mail/bin/answer.py?answer=6596 c13si5382730vcw.23", @tag=nil, @dump_available=false, @inactive=true, @can_activate=true, @message_id="876d40fe-ab2a-4925-9d6f-8d5e4f4926f5", @subject="Re: What, to you, is a large crowd?">

bounce.dump     # string, containing raw SMTP data
# => "Return-Path: <>\r\nDate: Sun, 21 Oct 2012 01:00:04 -0400\r\nFrom: postmaster@p1.mtasv.net\r\n..."

bounce.activate # reactivate hard bounce
# => #<Postmark::Bounce:0x007ff09c04ae18 @id=580516117, @email="sheldon@bigbangtheory.com", @bounced_at=2012-10-21 00:01:56 +0800, @type="HardBounce", @name=nil, @details="smtp;550 5.1.1 The email account that you tried to reach does not exist. Please try double-checking the recipient's email address for typos or unnecessary spaces. Learn more at http://support.google.com/mail/bin/answer.py?answer=6596 c13si5382730vcw.23", @tag=nil, @dump_available=false, @inactive=true, @can_activate=true, @message_id="876d40fe-ab2a-4925-9d6f-8d5e4f4926f5", @subject="Re: What, to you, is a large crowd?">
```

## Encryption

To use SSL encryption when sending email configure the library as follows:

``` ruby
Postmark.secure = true
```

## Requirements

The gem relies on Mail or TMail for building the message. You will also need
postmark account, server and sender signature set up to use it.
If you plan using it in a rails project, check out the postmark-rails gem, which
is meant to integrate with ActionMailer.

The plugin will try to use ActiveSupport Json if it is already included. If not,
it will attempt using the built-in ruby Json library.

You can also explicitly specify which one to be used, using

``` ruby
Postmark.response_parser_class = :Json # :ActiveSupport or :Yajl are also supported.
```

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
* Send me a pull request. Bonus points for topic branches.

## Authors & Contributors

* Petyo Ivanov
* Ilya Sabanin
* Artem Chistyakov
* Hristo Deshev
* Dmitry Sabanin
* Randy Schmidt
* Chris Williams
* Aitor García Rey
* James Miller
* Yury Batenko
* Pavel Maksimenko
* Anton Astashov
* Marcus Brito
* Tyler Hunt

## Copyright

Copyright (c) 2013 Wildbit LLC. See LICENSE for details.
