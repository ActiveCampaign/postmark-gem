shared_examples :mail do
  it "should set text body for plain message" do
    Postmark.send(:convert_message_to_options_hash, subject)['TextBody'].should_not be_nil
  end

  it "should encode from properly when name is used" do
    subject.from = "Sheldon Lee Cooper <sheldon@bigbangtheory.com>"
    subject.should be_serialized_to %q[{"Subject":"Hello!", "From":"Sheldon Lee Cooper <sheldon@bigbangtheory.com>", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode reply to" do
    subject.reply_to = ['a@a.com', 'b@b.com']
    subject.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "ReplyTo":"a@a.com, b@b.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode tag" do
    subject.tag = "invite"
    subject.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "Tag":"invite", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode multiple recepients (TO)" do
    subject.to = ['a@a.com', 'b@b.com']
    subject.should be_serialized_to %q[{"Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"a@a.com, b@b.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode multiple recepients (CC)" do
    subject.cc = ['a@a.com', 'b@b.com']
    subject.should be_serialized_to %q[{"Cc":"a@a.com, b@b.com", "Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should encode multiple recepients (BCC)" do
    subject.bcc = ['a@a.com', 'b@b.com']
    subject.should be_serialized_to %q[{"Bcc":"a@a.com, b@b.com", "Subject":"Hello!", "From":"sheldon@bigbangtheory.com", "To":"lenard@bigbangtheory.com", "TextBody":"Hello Sheldon!"}]
  end

  it "should accept string as reply_to field" do
    subject.reply_to = ['Anton Astashov <b@b.com>']
    subject.should be_serialized_to %q[{"From": "sheldon@bigbangtheory.com", "ReplyTo": "b@b.com", "To": "lenard@bigbangtheory.com", "Subject": "Hello!", "TextBody": "Hello Sheldon!"}]
  end
end
