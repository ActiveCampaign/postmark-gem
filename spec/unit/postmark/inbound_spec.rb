require 'spec_helper'

describe Postmark::Inbound do
  # http://developer.postmarkapp.com/developer-inbound-parse.html#example-hook
  let(:example_inbound) { '{"From":"myUser@theirDomain.com","FromFull":{"Email":"myUser@theirDomain.com","Name":"John Doe"},"To":"451d9b70cf9364d23ff6f9d51d870251569e+ahoy@inbound.postmarkapp.com","ToFull":[{"Email":"451d9b70cf9364d23ff6f9d51d870251569e+ahoy@inbound.postmarkapp.com","Name":""}],"Cc":"\"Full name\" <sample.cc@emailDomain.com>, \"Another Cc\" <another.cc@emailDomain.com>","CcFull":[{"Email":"sample.cc@emailDomain.com","Name":"Full name"},{"Email":"another.cc@emailDomain.com","Name":"Another Cc"}],"ReplyTo":"myUsersReplyAddress@theirDomain.com","Subject":"This is an inbound message","MessageID":"22c74902-a0c1-4511-804f2-341342852c90","Date":"Thu, 5 Apr 2012 16:59:01 +0200","MailboxHash":"ahoy","TextBody":"[ASCII]","HtmlBody":"[HTML(encoded)]","Tag":"","Headers":[{"Name":"X-Spam-Checker-Version","Value":"SpamAssassin 3.3.1 (2010-03-16) onrs-ord-pm-inbound1.wildbit.com"},{"Name":"X-Spam-Status","Value":"No"},{"Name":"X-Spam-Score","Value":"-0.1"},{"Name":"X-Spam-Tests","Value":"DKIM_SIGNED,DKIM_VALID,DKIM_VALID_AU,SPF_PASS"},{"Name":"Received-SPF","Value":"Pass (sender SPF authorized) identity=mailfrom; client-ip=209.85.160.180; helo=mail-gy0-f180.google.com; envelope-from=myUser@theirDomain.com; receiver=451d9b70cf9364d23ff6f9d51d870251569e+ahoy@inbound.postmarkapp.com"},{"Name":"DKIM-Signature","Value":"v=1; a=rsa-sha256; c=relaxed\/relaxed;        d=wildbit.com; s=google;        h=mime-version:reply-to:date:message-id:subject:from:to:cc         :content-type;        bh=cYr\/+oQiklaYbBJOQU3CdAnyhCTuvemrU36WT7cPNt0=;        b=QsegXXbTbC4CMirl7A3VjDHyXbEsbCUTPL5vEHa7hNkkUTxXOK+dQA0JwgBHq5C+1u         iuAJMz+SNBoTqEDqte2ckDvG2SeFR+Edip10p80TFGLp5RucaYvkwJTyuwsA7xd78NKT         Q9ou6L1hgy\/MbKChnp2kxHOtYNOrrszY3JfQM="},{"Name":"MIME-Version","Value":"1.0"},{"Name":"Message-ID","Value":"<CAGXpo2WKfxHWZ5UFYCR3H_J9SNMG+5AXUovfEFL6DjWBJSyZaA@mail.gmail.com>"}],"Attachments":[{"Name":"myimage.png","Content":"[BASE64-ENCODED CONTENT]","ContentType":"image/png","ContentLength":4096},{"Name":"mypaper.doc","Content":"[BASE64-ENCODED CONTENT]","ContentType":"application/msword","ContentLength":16384}]}' }

  context "given a serialized inbound document" do
    subject { Postmark::Inbound.to_ruby_hash(example_inbound) }

    it { should have_key(:from) }
    it { should have_key(:from_full) }
    it { should have_key(:to) }
    it { should have_key(:to_full) } 
    it { should have_key(:cc) }
    it { should have_key(:cc_full) }
    it { should have_key(:reply_to) }
    it { should have_key(:subject) }
    it { should have_key(:message_id) }
    it { should have_key(:date) }
    it { should have_key(:mailbox_hash) }
    it { should have_key(:text_body) }
    it { should have_key(:html_body) }
    it { should have_key(:tag) }
    it { should have_key(:headers) }
    it { should have_key(:attachments) }

    context "cc" do
      it 'has 2 CCs' do
        subject[:cc_full].count.should == 2
      end

      it 'stores CCs as an array of Ruby hashes' do
        cc = subject[:cc_full].last
        cc.should have_key(:email)
        cc.should have_key(:name)
      end
    end

    context "to" do
      it 'has 1 recipients' do
        subject[:to_full].count.should == 1
      end

      it 'stores TOs as an array of Ruby hashes' do
        cc = subject[:to_full].last
        cc.should have_key(:email)
        cc.should have_key(:name)
      end
    end

    context "from" do
      it 'is a hash' do
        subject[:from_full].should be_a Hash
      end

      it 'should have all required fields' do
        subject[:from_full].should have_key(:email)
        subject[:from_full].should have_key(:name)
      end
    end

    context "headers" do
      it 'has 8 headers' do
        subject[:headers].count.should == 8
      end

      it 'stores headers as an array of Ruby hashes' do
        header = subject[:headers].last
        header.should have_key(:name)
        header.should have_key(:value)
      end
    end

    context "attachments" do
      it 'has 2 attachments' do
        subject[:attachments].count.should == 2
      end

      it 'stores attachemnts as an array of Ruby hashes' do
        attachment = subject[:attachments].last
        attachment.should have_key(:name)
        attachment.should have_key(:content)
        attachment.should have_key(:content_type)
        attachment.should have_key(:content_length)
      end
    end
  end
end