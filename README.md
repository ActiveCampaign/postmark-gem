# Postmark Gem

This gem is an official wrapper for [Postmark HTTP API](http://postmarkapp.com). Use it to send emails and retrieve info about bounces.

## Getting Started

### Install the gem

``` bash
gem install postmark
```

### Install [Mail](http://rubygems.org/gems/mail) library

In addition to the `postmark` gem you also need to install `mail` gem.

``` bash
gem install mail
```

You can also use the gem with `tmail` library. This is not recommended for any
new projects, but may be useful for legacy Ruby 1.8.7 projects.

### Get Postmark API key

In order to send emails using Postmark ruby gem, you will need a
[Postmark](http://postmarkapp.com) account. If you don't have one please
register at https://postmarkapp.com/sign_up.

If you didn't create any servers yet, please create one, proceed to
`Credentials` tab and copy an API key. API keys should be frequently rotated for
security reasons.

## Using with [Mail](http://rubygems.org/gems/mail) library

Make sure you have a [sender signature](https://postmarkapp.com/signatures) for
every From email you specify. From can also accept array of addresses.

### Plain text message

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from            'sheldon@bigbangtheory.com'
  to              'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject         'Re: Come on, Sheldon. It will be fun.'
  body            'That\'s what you said about the Green Lantern movie. You' \
                  'were 114 minutes of wrong.'

  delivery_method Mail::Postmark, :api_key => 'your-postmark-api-key'
end

message.deliver
# => #<Mail::Message:70355890541720, Multipart: false, Headers: <From: sheldon@bigbangtheory.com>, <To: leonard@bigbangtheory.com>, <Message-ID: e439fec0-4c89-475b-b3fc-eb446249a051>, <Subject: Re: Come on, Sheldon. It will be fun.>>
```

### HTML message

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from            'sheldon@bigbangtheory.com'
  to              'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject         'Re: What, to you, is a large crowd?'

  content_type    'text/html; charset=UTF-8'
  body            '<p>Any group big enough to trample me to death. General ' \
                  'rule of thumb is 36 adults or 70 children.</p>'

  delivery_method Mail::Postmark, :api_key => 'your-postmark-api-key'
end

message.deliver
# => #<Mail::Message:70355902117460, Multipart: false, Headers: <From: sheldon@bigbangtheory.com>, <To: leonard@bigbangtheory.com>, <Message-ID: 3a9370a2-6c24-4304-a03c-320a54cc59f7>, <Subject: Re: What, to you, is a large crowd?>, <Content-Type: text/html; charset=UTF-8>>
```

### Message with attachments

You can use postmark gem to send messages with attachments. Please note that:

* Only allowed file types can be sent as attachments. The message will be rejected (or you will get an SMTP API bounce if using SMTP) with a description of the rejected file, if you try to send a file with a disallowed extension.
* Attachment size can be 10 MB at most. That means you can send three attachments weighing at three megabytes each, but you won't be able to send a single 11MB attachment. Don't worry about base64 encoding making your data larger than it really is. Attachment size is calculated using the real binary data (after base64-decoding it).
* Many applications can get away with sending email as a response to a user action and do that right in the same web request handler. Sending attachments changes that. Message size can and will get bigger and the time to submit it to the Postmark servers will get longer. That is why we recommend that you send email with attachments from a background job. Your users will love you for that!

Check out our [special documentation section](http://developer.postmarkapp.com/developer-build.html#attachments)
for detailed information.

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from            'leonard@bigbangtheory.com'
  to              'Dr. Sheldon Cooper <sheldon@bigbangtheory.com>'
  subject         'Have you seen these pictures of yours?'
  body            'You look like a real geek!'

  delivery_method Mail::Postmark, :api_key => 'your-postmark-api-key'
end

message.postmark_attachments = [File.open("1.jpeg"), File.open("2.jpeg")]

message.deliver
# => <Mail::Message:70235449249320, Multipart: false, Headers: <From: leonard@bigbangtheory.com>, <To: sheldon@bigbangtheory.com>, <Message-ID: 91cbdb90-9daa-455d-af24-e233711b02c2>, <Subject: Have you seen these pictures of yours?>>
```

### Multipart message

You can send multipart messages containing both text and HTML using Postmark gem.

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from            'sheldon@bigbangtheory.com'
  to              'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject         'Re: Anything Can Happen Thursday'
  delivery_method Mail::Postmark, :api_key => 'your-postmark-api-key'

  text_part do
    body          'Apparently the news didn\'t reach my digestive system,' \
                  ' which when startled has it\'s own version of "Anything' \
                  ' Can Happen Thursday"'
  end

  html_part do
    content_type  'text/html; charset=UTF-8'
    body          '<p>Apparently the news didn&rsquo;t reach my digestive ' \
                  'system, which when startled has it&rsquo;s own version ' \
                  'of &ldquo;Anything Can Happen Thursday&rdquo;</p>'
  end
end

message.deliver
# => #<Mail::Message:70355901588620, Multipart: true, Headers: <From: sheldon@bigbangtheory.com>, <To: leonard@bigbangtheory.com>, <Message-ID: cadba131-f6d6-4cfc-9892-16ee738ba54c>, <Subject: Re: Anything Can Happen Thursday>, <Content-Type: multipart/alternative; boundary=--==_mimepart_50ef7a6234a69_a4c73ffd01035adc207b8>>
```

### Tagged message

Postmark also lets you tag your messages.

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from           'sheldon@bigbangtheory.com'
  to             'Penny <penny@bigbangtheory.com>'
  subject        'Re: You cleaned my apartment???'
  body           'I couldn\'t sleep knowing that just outside my bedroom is ' \
                 'our living room and just outside our living room is that ' \
                 'hallway and immediately adjacent to that hallway is this!'

  delivery_method Mail::Postmark, :api_key => 'your-postmark-api-key'
end

message.tag = 'confidential'

message.deliver
# => #<Mail::Message:70168327829580, Multipart: false, Headers: <From: sheldon@bigbangtheory.com>, <To: penny@bigbangtheory.com>, <Message-ID: af2570fd-3481-4b45-8b27-a249806d891a>, <Subject: Re: You cleaned my apartment???>, <TAG: confidential>>
```

### Accessing Postmark Message-ID

You might want to save identifiers of messages you send. Postmark provides you
with unique Message-ID, which you can
[use to retrieve bounces](http://blog.postmarkapp.com/post/24970994681/using-messageid-to-retrieve-bounces)
later. This example shows you how to access Message-ID of a sent email message.

``` ruby
message = Mail.new
# ...
message.deliver

message['Message-ID']
# => cadba131-f6d6-4cfc-9892-16ee738ba54c
message.message_id
# => "cadba131-f6d6-4cfc-9892-16ee738ba54c"
```

## Using with [TMail](http://rubygems.org/gems/tmail) library

Postmark gem also supports `tmail` library, which can be used by Ruby 1.8.7
users working on legacy projects. Please note that TMail is not supported since
2010, so please consider using new ruby [mail](http://rubygems.org/gems/mail)
library for all your new projects.

Make sure you have a [sender signature](https://postmarkapp.com/signatures) for
every From email you specify. From can also accept array of addresses.

``` ruby
require 'rubygems'
require 'postmark'
require 'tmail'
require 'json'

Postmark.api_key = 'your-postmark-api-key'

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

## Exploring Other API Features

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

## Security

To use SSL encryption when sending email configure the library as follows:

``` ruby
Postmark.secure = true
```

## Requirements

The gem relies on Mail or TMail for building the message. You will also need
postmark account, server and sender signature set up to use it.
If you plan using it in a rails project, check out the
[postmark-rails](https://github.com/wildbit/postmark-rails/) gem, which
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

Copyright © 2013 Wildbit LLC. See LICENSE for details.
