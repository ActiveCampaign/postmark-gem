##
# author: http://fernandoguillen.info
# date: 2008-08-27
#
# When you have a TMail::Mail with plain text and html body parts
# there is not any easy way to extract just the html body part
#
# This is a patch to try to resolve this
#
# just require 'extensions/tmail'
# and every TMail::Mail object will have the .body_html method
#

module TMail
  class Mail
    
    include Postmark::SharedMessageExtensions

    #
    # returs an String with just the html part of the body
    # or nil if there is not any html part
    #
    def body_html
      result = nil
      if multipart?
        parts.each do |part|
          if part.multipart?
            part.parts.each do |part2|
              result = part2.unquoted_body if part2.content_type =~ /html/i
            end
          elsif !attachment?(part)
            result = part.unquoted_body if part.content_type =~ /html/i
          end
        end
      else
        result = unquoted_body if content_type =~ /html/i
      end
      result
    end

    #
    # returs an String with just the plain text part of the body
    # or nil if there is not any plain text part
    #
    def body_text
      result = unquoted_body
      if multipart?
        parts.each do |part|
          if part.multipart?
            part.parts.each do |part2|
              result = part2.unquoted_body if part2.content_type =~ /plain/i
            end
          elsif !attachment?(part)
            result = part.unquoted_body if part.content_type =~ /plain/i
          end
        end
      else
        result = unquoted_body if content_type =~ /plain/i
      end
      result
    end

    #
    # This is only for develop.
    # print on output all the parts of the Mail with some details
    #
    def parts_observer
      puts "INI"
      puts "content_type: #{content_type}"
      puts "body: #{body}"
      puts "parts.size: #{parts.size}"

      if multipart?
        parts.each_with_index do |part, index|
          puts ""
          puts "  parts[#{index}]"
          puts "    content_type: #{part.content_type}"
          puts "    multipart? #{part.multipart?}"

          header = part["content-type"]

          if part.multipart?
            puts "    --multipart--"
            part.parts.each_with_index do |part2, index2|
              puts "    part[#{index}][#{index2}]"
              puts "      content_type: #{part2.content_type}"
              puts "      body: #{part2.unquoted_body}"
            end
          elsif header.nil?
            puts "    --header nil--"
          elsif !attachment?(part)
            puts "    --no multipart, no header nil, no attachment--"
            puts "      content_type: #{part.content_type}"
            puts "      body: #{part.unquoted_body}"
          else
            puts "    --no multipart, no header nil, attachment--"
            puts "     content_type: #{part.content_type}"
          end

        end
      else
        puts "  --no multipart--"
        puts "    content_type: #{content_type}"
        puts "    body: #{unquoted_body}"
      end

      puts "END"
    end

  end
end
