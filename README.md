# Postmark Gem
[![Build Status](https://travis-ci.org/wildbit/postmark-gem.svg?branch=master)](https://travis-ci.org/wildbit/postmark-gem) [![Code Climate](https://codeclimate.com/github/wildbit/postmark-gem/badges/gpa.svg)](https://codeclimate.com/github/wildbit/postmark-gem)

This gem is the official wrapper for the [Postmark HTTP API](http://postmarkapp.com). Postmark allows you to send your application's emails with high delivery rates, including bounce/spam processing and detailed statistics. In addition, Postmark can parse incoming emails which are forwarded back to your application.

## Install the gem

With Bundler:

``` ruby
gem 'postmark'
```

Without Bundler:

``` bash
gem install postmark
```

## Get a Postmark API token

In order to send emails using Postmark ruby gem, you will need a
[Postmark](http://postmarkapp.com) account. If you don't have one please
register at https://postmarkapp.com/sign_up.

If you didn’t create any servers yet, please create one, proceed to the
`Credentials` tab and copy an API token. API tokens should be frequently rotated for
security reasons.

## Communicating with the API

Make sure you have a [sender signature](https://postmarkapp.com/signatures) for
every From email address you specify.

Create an instance of `Postmark::ApiClient` to start sending emails.

``` ruby
your_api_token = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
client = Postmark::ApiClient.new(your_api_token)
```

`Postmark::ApiClient` accepts various options:

``` ruby
client = Postmark::ApiClient.new(your_api_token, http_open_timeout: 15)
```

Some useful options are:

* `secure` (`true` or `false`): set to false to disable SSL connection.
* `http_read_timeout` (positive number): limit HTTP read time to `n` seconds.
* `http_open_timeout` (positive number): limit HTTP open time to `n` seconds.
* `proxy_host` (string): proxy address to use.
* `proxy_port` (positive number): proxy port to use.
* `proxy_user` (string): proxy user.
* `proxy_pass` (string): proxy password.

## Sending a plain text message

``` ruby
client.deliver(from: 'sheldon@bigbangtheory.com',
               to: 'Leonard Hofstadter <leonard@bigbangtheory.com>',
               subject: 'Re: Come on, Sheldon. It will be fun.',
               text_body: 'That\'s what you said about the Green Lantern ' \
                          'movie. You were 114 minutes of wrong.')
# => {:to=>"Leonard Hofstadter <leonard@bigbangtheory.com>", :submitted_at=>"2013-05-09T02:45:16.2059023-04:00", :message_id=>"b2b268e3-6a70-xxxx-b897-49c9eb8b1d2e", :error_code=>0, :message=>"OK"}
```

## Sending an HTML message with open tracking

Simply pass an HTML document as html_body parameter to `#deliver`. You can also enable open tracking by setting `track_opens` to `true`.

``` ruby
client.deliver(from: 'sheldon@bigbangtheory.com',
               to: 'Leonard Hofstadter <leonard@bigbangtheory.com>',
               subject: 'Re: What, to you, is a large crowd?',
               html_body: '<p>Any group big enough to trample me to death. ' \
                          'General rule of thumb is 36 adults or 70 ' \
                          'children.</p>',
               track_opens: true)
# => {:to=>"Leonard Hofstadter <leonard@bigbangtheory.com>", :submitted_at=>"2013-05-09T02:51:08.8789433-04:00", :message_id=>"75c28987-564e-xxxx-b6eb-e8071873ac06", :error_code=>0, :message=>"OK"}
```
## Sending a message with link tracking

To track visited links for emails you send, make sure to have links in html_body, text_body or both when passing them to `#deliver`. You need to enable link tracking by setting `track_links` parameter to one of the following options: `:html_only`, `:text_only`, `:html_and_text` or `:none`.
Depending on parameter you set, link tracking will be enabled on plain text body, html body, both or none. Optionally you can also use string values as parameters 'HtmlOnly', 'TextOnly', 'HtmlAndText' or 'None'.

``` ruby
client.deliver(from: 'sheldon@bigbangtheory.com',
               to: 'Leonard Hofstadter <leonard@bigbangtheory.com>',
               subject: 'Re: What, to you, is a large crowd?',
               html_body: '<p>Any group big enough to trample me to death. ' \
                          'General <a href="http://www.example.com">rule of thumb</a> is 36 adults or 70 ' \
                          'children.</p>',
               text_body: 'Any group big enough to trample me to death. General rule of thumb is 36 adults or 70 children - http://www.example.com.',
               track_links: :html_and_text)
# => {:to=>"Leonard Hofstadter <leonard@bigbangtheory.com>", :submitted_at=>"2013-05-09T02:51:08.8789433-04:00", :message_id=>"75c28987-564e-xxxx-b6eb-e8071873ac06", :error_code=>0, :message=>"OK"}
```

## Sending a message with attachments

You can add
[attachments](http://developer.postmarkapp.com/developer-build.html#attachments)
to your messages. Keep in mind message size limit (contents and attachment) is currently 10 MB. For inline attachments it is possible to specify content IDs via the `content_id` attribute.

``` ruby
client.deliver(from: 'leonard@bigbangtheory.com',
               to: 'Dr. Sheldon Cooper <sheldon@bigbangtheory.com>',
               subject: 'Have you seen these pictures of yours?',
               text_body: 'You look like a real geek!',
               html_body: '<p>You look like a real geek!</p><center><img src="cid:42"></center>',
               attachments: [File.open('1.jpeg'),
                             {name: 'sheldon.jpeg',
                              content: [File.read('2.jpeg')].pack('m'),
                              content_type: 'image/jpeg'},
                             {name: 'logo.png',
                              content: [File.read('1.png')].pack('m'),
                              content_type: 'image/png',
                              content_id: 'cid:42'}])

# => {:to=>"Dr. Sheldon Cooper <sheldon@bigbangtheory.com>", :submitted_at=>"2013-05-09T02:56:12.2828813-04:00", :message_id=>"8ec0d283-8b93-xxxx-9d65-241d1777cf0f", :error_code=>0, :message=>"OK"}
```

## Sending a multipart message

``` ruby
client.deliver(from: 'sheldon@bigbangtheory.com',
               to: 'Leonard Hofstadter <leonard@bigbangtheory.com>',
               subject: 'Re: Anything Can Happen Thursday',
               text_body: 'Apparently the news didn\'t reach my digestive ' \
                          'system, which when startled has it\'s own version ' \
                          'of "Anything Can Happen Thursday"',
               html_body: '<p>Apparently the news didn&rsquo;t reach my ' \
                          'digestive system, which when startled has ' \
                          'it&rsquo;s own version of &ldquo;Anything Can '\
                          'Happen Thursday&rdquo;</p>')
# => {:to=>"Leonard Hofstadter <leonard@bigbangtheory.com>", :submitted_at=>"2013-05-09T02:58:00.089828-04:00", :message_id=>"bc973458-1315-xxxx-b295-6aa0a2b631ac", :error_code=>0, :message=>"OK"}
```

## Tagging messages

You can categorize outgoing email using the optional `:tag` property. If you use
different tags for the different types of emails your application generates,
you will be able to get detailed statistics for them through the Postmark user
interface.

``` ruby
client.deliver(from: 'sheldon@bigbangtheory.com',
               to: 'Penny <penny@bigbangtheory.com>',
               subject: 'Re: You cleaned my apartment???',
               text_body: 'I couldn\'t sleep knowing that just outside my ' \
                     'bedroom is our living room and just outside our ' \
                     'living room is that hallway and immediately adjacent ' \
                     'to that hallway is this!',
               tag: 'confidential')

# => {:to=>"Penny <penny@bigbangtheory.com>", :submitted_at=>"2013-05-09T03:00:55.4454938-04:00", :message_id=>"34aed4b3-3a95-xxxx-bd1d-88064909cc93", :error_code=>0, :message=>"OK"}
```

## Sending to multiple recipients

You can pass multiple recipient addresses in the `:to` field and the optional
`:cc` and `:bcc` fields. Note that Postmark has a limit of 50 recipients
per message in total. You need to take care not to exceed that limit.
Otherwise, you will get an error.

``` ruby
client.deliver(from: 'sheldon@bigbangtheory.com',
               to: ['Leonard Hofstadter <leonard@bigbangtheory.com>',
                    'Penny <penny@bigbangtheory.com>'],
               cc: ['Dr. Koothrappali <raj@bigbangtheory.com>'],
               bcc: 'secretsheldonstorage@bigbangtheory.com',
               subject: 'Re: Come on, Sheldon. It will be fun.',
               text_body: 'That\'s what you said about the Green Lantern ' \
                          'movie. You were 114 minutes of wrong.')
# => {:to=>"Leonard Hofstadter <leonard@bigbangtheory.com>, Penny <penny@bigbangtheory.com>", :submitted_at=>"2013-05-09T05:04:16.3247488-04:00", :message_id=>"d647c5d6-xxxx-466d-9411-557dcd5c2297", :error_code=>0, :message=>"OK"}
```

## Sending a templated email

If you have a [template created](https://github.com/wildbit/postmark-gem/wiki/The-Templates-API-support) in Postmark you can send an email using that template. 

``` ruby
client.deliver_with_template(from: 'sheldon@bigbangtheory.com',
                             to: 'Penny <penny@bigbangtheory.com>',
                             template_id: 123,
                             template_model: {
                               name: 'Penny',
                               message: 'Bazinga!'
                             })

# => {:to=>"Penny <penny@bigbangtheory.com>", :submitted_at=>"2013-05-09T03:00:55.4454938-04:00", :message_id=>"34aed4b3-3a95-xxxx-bd1d-88064909cc93", :error_code=>0, :message=>"OK"}
```

## Sending in batches

While Postmark is focused on transactional email, we understand that developers
with higher volumes or processing time constraints need to send their messages
in batches. To facilitate this we provide a batching endpoint that permits you
to send up to 500 well-formed Postmark messages in a single API call.

``` ruby
messages = []

messages << {from: 'sheldon@bigbangtheory.com',
             to: 'Leonard Hofstadter <leonard@bigbangtheory.com>',
             subject: 'Re: Come on, Sheldon. It will be fun.',
             text_body: 'That\'s what you said about the Green Lantern ' \
                        'movie. You were 114 minutes of wrong.'}

messages << {from: 'sheldon@bigbangtheory.com',
             to: 'Penny <penny@bigbangtheory.com>',
             subject: 'Re: You cleaned my apartment???',
             text_body: 'I couldn\'t sleep knowing that just outside my ' \
                        'bedroom is our living room and just outside our ' \
                        'living room is that hallway and immediately ' \
                        'adjacent to that hallway is this!',
             tag: 'confidential'}

client.deliver_in_batches(messages)
# => [{:to=>"Leonard Hofstadter <leonard@bigbangtheory.com>", :submitted_at=>"2013-05-09T05:19:16.3361118-04:00", :message_id=>"247e43a9-6b0d-4914-a87f-7b74bf76b5cb", :error_code=>0, :message=>"OK"}, {:to=>"Penny <penny@bigbangtheory.com>", :submitted_at=>"2013-05-09T05:19:16.3517099-04:00", :message_id=>"26467642-f169-4da8-87a8-b89154067dfb", :error_code=>0, :message=>"OK"}]
```

## Parsing inbound

Inbound processing allows you (or your users) to send emails to Postmark, which we then
process and deliver to you via a web hook in a nicely formatted JSON document.

Here is a simple Ruby/Sinatra application that does basic inbound processing.

``` ruby
logger = Logger.new(STDOUT)

class Comment
  attr_accessor :attributes

  def self.create_from_inbound_hook(message)
    self.new(:text => message["TextBody"],
             :user_email => message["From"],
             :discussion_id => message["MailboxHash"])
  end

  def initialize(attributes={})
    @attributes = attributes
  end
end

post '/inbound' do
  request.body.rewind
  comment = Comment.create_from_inbound_hook(Postmark::Json.decode(request.body.read))
  logger.info comment.inspect
end
```

If you don’t like that the fields of the Inbound JSON document are all in CamelCase, you
can use the `Postmark::Inbound.to_ruby_hash` method to give it some Ruby flavor.

```
postmark_hash = Postmark::Json.decode(request.body.read)
ruby_hash = Postmark::Inbound.to_ruby_hash(postmark_hash)
# => {:from=>"myUser@theirDomain.com", :from_full=>{:email=>"myUser@theirDomain.com", :name=>"John Doe"}, :to=>"451d9b70cf9364d23ff6f9d51d870251569e+ahoy@inbound.postmarkapp.com", :to_full=>[{:email=>"451d9b70cf9364d23ff6f9d51d870251569e+ahoy@inbound.postmarkapp.com", :name=>""}], :cc=>"\"Full name\" <sample.cc@emailDomain.com>, \"Another Cc\" <another.cc@emailDomain.com>", :cc_full=>[{:email=>"sample.cc@emailDomain.com", :name=>"Full name"}, {:email=>"another.cc@emailDomain.com", :name=>"Another Cc"}], :reply_to=>"myUsersReplyAddress@theirDomain.com", :subject=>"This is an inbound message", :message_id=>"22c74902-a0c1-4511-804f2-341342852c90", :date=>"Thu, 5 Apr 2012 16:59:01 +0200", :mailbox_hash=>"ahoy", :text_body=>"[ASCII]", :html_body=>"[HTML(encoded)]", :tag=>"", :headers=>[{:name=>"X-Spam-Checker-Version", :value=>"SpamAssassin 3.3.1 (2010-03-16) onrs-ord-pm-inbound1.wildbit.com"}, {:name=>"X-Spam-Status", :value=>"No"}, {:name=>"X-Spam-Score", :value=>"-0.1"}, {:name=>"X-Spam-Tests", :value=>"DKIM_SIGNED,DKIM_VALID,DKIM_VALID_AU,SPF_PASS"}, {:name=>"Received-SPF", :value=>"Pass (sender SPF authorized) identity=mailfrom; client-ip=209.85.160.180; helo=mail-gy0-f180.google.com; envelope-from=myUser@theirDomain.com; receiver=451d9b70cf9364d23ff6f9d51d870251569e+ahoy@inbound.postmarkapp.com"}, {:name=>"DKIM-Signature", :value=>"v=1; a=rsa-sha256; c=relaxed/relaxed;        d=wildbit.com; s=google;        h=mime-version:reply-to:date:message-id:subject:from:to:cc         :content-type;        bh=cYr/+oQiklaYbBJOQU3CdAnyhCTuvemrU36WT7cPNt0=;        b=QsegXXbTbC4CMirl7A3VjDHyXbEsbCUTPL5vEHa7hNkkUTxXOK+dQA0JwgBHq5C+1u         iuAJMz+SNBoTqEDqte2ckDvG2SeFR+Edip10p80TFGLp5RucaYvkwJTyuwsA7xd78NKT         Q9ou6L1hgy/MbKChnp2kxHOtYNOrrszY3JfQM="}, {:name=>"MIME-Version", :value=>"1.0"}, {:name=>"Message-ID", :value=>"<CAGXpo2WKfxHWZ5UFYCR3H_J9SNMG+5AXUovfEFL6DjWBJSyZaA@mail.gmail.com>"}], :attachments=>[{:name=>"myimage.png", :content=>"[BASE64-ENCODED CONTENT]", :content_type=>"image/png", :content_length=>4096}, {:name=>"mypaper.doc", :content=>"[BASE64-ENCODED CONTENT]", :content_type=>"application/msword", :content_length=>16384}]}
```

## Working with bounces

Use `#get_bounces` to retrieve a list of bounces (use `:count` and `:offset`
parameters to control pagination).

``` ruby
client.get_bounces(count: 1, offset: 0)
# => [{:id=>654714902, :type=>"Transient", :type_code=>2, :name=>"Message delayed", :message_id=>"1fdf3729-xxxx-4d5c-8a7b-96da7a23268b", :description=>"The server could not temporarily deliver your message (ex: Message is delayed due to network troubles).", :details=>"action: failed\r\n", :email=>"tema@wildbit.org", :bounced_at=>"2013-04-10T01:01:35.0965184-04:00", :dump_available=>true, :inactive=>false, :can_activate=>true, :subject=>"bounce test"}]
```

Use `#get_bounced_tags` to retrieve a list of tags used for bounced emails.

``` ruby
client.get_bounced_tags
# => ["confidential"]
```

Use `#get_bounce` to get info for a specific bounce using ID:

``` ruby
client.get_bounce(654714902)
# => {:id=>654714902, :type=>"Transient", :type_code=>2, :name=>"Message delayed", :message_id=>"1fdf3729-xxxx-xxxx-8a7b-96da7a23268b", :description=>"The server could not temporarily deliver your message (ex: Message is delayed due to network troubles).", :details=>"action: failed\r\n", :email=>"tema@wildbit.com", :bounced_at=>"2013-04-10T01:01:35.0965184-04:00", :dump_available=>true, :inactive=>false, :can_activate=>true, :subject=>"bounce test", :content=>"..."}
```

Use `#dump_bounce` to get the full bounce body:

``` ruby
client.dump_bounce(654714902)
# => {:body=>"Return-Path: <>\r\nReceived: from m1.mtasv.net (74.205.19.136) by sc-ord-mail2.mtasv.net id hcjov61jk5ko for <pm_bounces@pm.mtasv.net>; Wed, 10 Apr 2013 01:00:35 -0400 (envelope-from <>)\r\nDate: Wed, 10 Apr 2013 01:00:48 -0400\r\nFrom: postmaster@m1.mtasv.net\r\n..."}
```

There is a `#bounces` enumerator to take the underlying complexity off of your shoulders. Use it to iterate over all of your bounces.

``` ruby
client.bounces.first(5)
# => [{...}, {...}]
```

You can activate email addresses that were disabled due to a hard bounce by using `#activate_bounce`:

``` ruby
client.activate_bounce(654714902)
# => {:id=>654714902, :type=>"Transient", :type_code=>2, :name=>"Message delayed", :message_id=>"1fdf3729-xxxx-xxxx-xxxx-96da7a23268b", :description=>"The server could not temporarily deliver your message (ex: Message is delayed due to network troubles).", :details=>"action: failed\r\n", :email=>"tema@wildbit.com", :bounced_at=>"2013-04-10T01:01:35.0965184-04:00", :dump_available=>true, :inactive=>false, :can_activate=>true, :subject=>"bounce test"}
```

## Getting delivery stats

Currently delivery stats only include a summary of inactive emails and bounces
by type.

``` ruby
stats = client.delivery_stats
# => {:inactive_mails=>1, :bounces=>[{:name=>"All", :count=>3}, {:type=>"HardBounce", :name=>"Hard bounce", :count=>2}, {:type=>"Transient", :name=>"Message delayed", :count=>1}]}
```

## Server Info

The gem also allows you to read and update the server info:

``` ruby
client.server_info
# => {:name=>"Testing", :color=>"blue", :bounce_hook_url=>"", :inbound_hash=>"c2ffffff74f8643e5f6086c81", :inbound_hook_url=>"", :smtp_api_activated=>true}
```

For example, you can use `#update_server_info` to set inbound hook URL:

``` ruby
client.update_server_info inbound_hook_url: 'http://example.org/bounces'
```

# Using Postmark with the [Mail](http://rubygems.org/gems/mail) library

You can use Postmark with the `mail` gem.

``` bash
gem install mail
```

Make sure you have a [sender signature](https://postmarkapp.com/signatures) for
every `From` email address you specify.

To send a `Mail::Message` via Postmark you’ll need to specify `Mail::Postmark` as
a delivery method for the message:

``` ruby
message = Mail.new do
  # ...
  delivery_method Mail::Postmark, api_token: 'your-postmark-api-token'
end
```

Delivery method accepts all options supported by `Postmark::ApiClient`
documented above. A new instance of `Postmark::ApiClient` is created every time
you deliver a message to preserve thread safety.

If you would prefer to use Postmark as the default delivery method for all
`Mail::Message` instances, you can call `Mail.defaults` method during the initialization
step of your app:

``` ruby
Mail.defaults do
  delivery_method Mail::Postmark, api_token: 'your-postmark-api-token'
end
```

## Plain text message

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

  delivery_method Mail::Postmark, :api_token => 'your-postmark-api-token'
end

message.deliver
# => #<Mail::Message:70355890541720, Multipart: false, Headers: <From: sheldon@bigbangtheory.com>, <To: leonard@bigbangtheory.com>, <Message-ID: e439fec0-4c89-475b-b3fc-eb446249a051>, <Subject: Re: Come on, Sheldon. It will be fun.>>
```

## HTML message (with open tracking)

Notice that we set `track_opens` field to `true`, to enable open tracking for this message.

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

  track_opens     true 

  delivery_method Mail::Postmark, :api_token => 'your-postmark-api-token'
end

message.deliver
# => #<Mail::Message:70355902117460, Multipart: false, Headers: <From: sheldon@bigbangtheory.com>, <To: leonard@bigbangtheory.com>, <Message-ID: 3a9370a2-6c24-4304-a03c-320a54cc59f7>, <Subject: Re: What, to you, is a large crowd?>, <Content-Type: text/html; charset=UTF-8>>
```

## Multipart message (with link tracking)

Notice that we set `track_links` field to `:html_and_text`, to enable link tracking for both plain text and html parts for this message.

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from            'sheldon@bigbangtheory.com'
  to              'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject         'Re: What, to you, is a large crowd?'

  text_part do
    body          'Any group big enough to trample me to death. General rule of thumb is 36 adults or 70 children - http://www.example.com.'
  end

  html_part do
    content_type  'text/html; charset=UTF-8'
    body          '<p>Any group big enough to trample me to death. ' \
                  'General <a href="http://www.example.com">rule of thumb</a> is 36 adults or 70 ' \
                  'children.</p>'
  end

  track_links     :html_and_text

  delivery_method Mail::Postmark, :api_token => 'your-postmark-api-token'
end

message.deliver
# => #<Mail::Message:70355902117460, Multipart: true, Headers: <From: sheldon@bigbangtheory.com>, <To: leonard@bigbangtheory.com>, <Message-ID: 1a1370a1-6c21-4304-a03c-320a54cc59f7>, <Subject: Re: What, to you, is a large crowd?>, <Content-Type: multipart/alternative; boundary=--==_mimepart_58380d6029b17_20543fd48543fa14977a>, <TRACK-LINKS: HtmlAndText>>
```

## Message with attachments

``` ruby
message = Mail.new do
  from            'leonard@bigbangtheory.com'
  to              'Dr. Sheldon Cooper <sheldon@bigbangtheory.com>'
  subject         'Have you seen these pictures of yours?'
  body            'You look like a real geek!'
  add_file        '1.jpeg'

  delivery_method Mail::Postmark, :api_token => 'your-postmark-api-token'
end

message.attachments['sheldon.jpeg'] = File.read('2.jpeg')

message.deliver
# => #<Mail::Message:70185826686240, Multipart: true, Headers: <From: leonard@bigbangtheory.com>, <To: sheldon@bigbangtheory.com>, <Message-ID: ba644cc1-b5b1-4bcb-aaf8-2f290b5aad80>, <Subject: Have you seen these pictures of yours?>, <Content-Type: multipart/mixed; boundary=--==_mimepart_5121f9f1ec653_12c53fd569035ad817726>>
```

You can also make an attachment inline:

``` ruby
message.attachments.inline['sheldon.jpeg'] = File.read('2.jpeg')
```

Then simply use `Mail::Part#url` method to reference it from your email body.

``` erb
<p><img src="<%= message.attachments['sheldon.jpeg'].url %>" alt="Dr. Sheldon Cooper"></p>
```

## Multipart message

You can send multipart messages containing both text and HTML using the Postmark gem.

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

message = Mail.new do
  from            'sheldon@bigbangtheory.com'
  to              'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject         'Re: Anything Can Happen Thursday'
  delivery_method Mail::Postmark, :api_token => 'your-postmark-api-token'

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

## Tagged message

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
  tag            'confidential'

  delivery_method Mail::Postmark, :api_token => 'your-postmark-api-token'
end

message.deliver
# => #<Mail::Message:70168327829580, Multipart: false, Headers: <From: sheldon@bigbangtheory.com>, <To: penny@bigbangtheory.com>, <Message-ID: af2570fd-3481-4b45-8b27-a249806d891a>, <Subject: Re: You cleaned my apartment???>, <TAG: confidential>>
```

## Sending in batches

You can also send `Mail::Message` objects in batches. Create an instance of
`Postmark::ApiClient` as described in "Communicating with the API" section.

``` ruby
messages = []

messages << Mail.new do
  from            'sheldon@bigbangtheory.com'
  to              'Leonard Hofstadter <leonard@bigbangtheory.com>'
  subject         'Re: Come on, Sheldon. It will be fun.'
  body            'That\'s what you said about the Green Lantern movie. You' \
                  'were 114 minutes of wrong.'
end

messages << Mail.new do
  from           'sheldon@bigbangtheory.com'
  to             'Penny <penny@bigbangtheory.com>'
  subject        'Re: You cleaned my apartment???'
  body           'I couldn\'t sleep knowing that just outside my bedroom is ' \
                 'our living room and just outside our living room is that ' \
                 'hallway and immediately adjacent to that hallway is this!'
  tag            'confidential'
end

client.deliver_messages(messages)
# => [{:to=>"leonard@bigbangtheory.com", :submitted_at=>"2013-05-10T01:59:29.830486-04:00", :message_id=>"8ad0e8b0-xxxx-xxxx-951d-223c581bb467", :error_code=>0, :message=>"OK"}, {:to=>"penny@bigbangtheory.com", :submitted_at=>"2013-05-10T01:59:29.830486-04:00", :message_id=>"33c6240c-xxxx-xxxx-b0df-40bdfcf4e0f7", :error_code=>0, :message=>"OK"}]
```

After delivering a batch you can check on each message’s delivery status:

``` ruby
messages.first.delivered?
# => true

messages.all?(&:delivered)
# => true
```

Or even get a related Postmark response:

``` ruby
messages.first.postmark_response
# => {"To"=>"leonard@bigbangtheory.com", "SubmittedAt"=>"2013-05-10T01:59:29.830486-04:00", "MessageID"=>"8ad0e8b0-xxxx-xxxx-951d-223c581bb467", "ErrorCode"=>0, "Message"=>"OK"}
```

## Accessing Postmark Message-ID

You might want to save identifiers of messages you send. Postmark provides you
with a unique Message-ID, which you can
[use to retrieve bounces](http://blog.postmarkapp.com/post/24970994681/using-messageid-to-retrieve-bounces)
later. This example shows you how to access the Message-ID of a sent email message.

``` ruby
message = Mail.new
# ...
message.deliver

message['Message-ID']
# => cadba131-f6d6-4cfc-9892-16ee738ba54c
message.message_id
# => "cadba131-f6d6-4cfc-9892-16ee738ba54c"
```

# Exploring Other Gem Features

## The Account API Support

Postmark allows you to automatically scale your sending infrastructure with the Account API. Learn how in the [Account API Support](https://github.com/wildbit/postmark-gem/wiki/The-Account-API-Support) guide.

## The Triggers API Support

[The Triggers API](https://github.com/wildbit/postmark-gem/wiki/The-Triggers-API-Support) can be used to tell Postmark to automatically track opens for all messages with a certain tag.

## The Messages API Support

If you ever need to access your messages or their metadata (i.e. open tracking info), [the Messages API](https://github.com/wildbit/postmark-gem/wiki/The-Messages-API-support) is a great place to start.

## The Templates API Support

[The Templates API](https://github.com/wildbit/postmark-gem/wiki/The-Templates-API-support) can be used to fully manage your templates.

## The Stats API Support

[The Stats API](https://github.com/wildbit/postmark-gem/wiki/The-Stats-API-support) can be used to access statistics on your emails sent by date and tag.


## ActiveModel-like Interface For Bounces

To provide an interface similar to ActiveModel for bounces, the Postmark gem adds
`Postmark::Bounce` class. This class uses the shared `Postmark::ApiClient` instance
configured through the Postmark module.

``` ruby
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

Postmark.response_parser_class = :Json
Postmark.api_token = 'your-postmark-api-token'

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

## Requirements

You will need a Postmark account, server and sender signature set up to use it.
If you plan using it in a Rails project, check out the
[postmark-rails](https://github.com/wildbit/postmark-rails/) gem, which
is meant to integrate with ActionMailer.

The plugin will try to use ActiveSupport Json if it is already included. If not,
it will attempt using the built-in Ruby Json library.

You can also explicitly specify which one to be used, using

``` ruby
Postmark.response_parser_class = :Json # :ActiveSupport or :Yajl are also supported.
```

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important to prevent future regressions.
* Do not mess with rakefile, version, or history
* Update the CHANGELOG, list your changes under Unreleased.
* Update the README if necessary.
* Write short, descriptive commit messages, following the format used in the repo.
* Send a pull request. Bonus points for topic branches.

## Copyright

Copyright © 2016 Wildbit LLC. See LICENSE for details.
