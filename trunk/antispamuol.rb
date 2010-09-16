#!/usr/bin/ruby -S
#
# antispamuol.rb --- Breaks UOL Anti-Spam

# Copyright  (C)  2010  Marcelo Toledo <marcelo@marcelotoledo.com>

# Version: 1.0
# Keywords: 
# Author: Marcelo Toledo <marcelo@marcelotoledo.com>
# Maintainer: Marcelo Toledo <marcelo@marcelotoledo.com>
# URL: http://

# Commentary: 



# Code:

require 'net/pop'
require 'rubygems'
require 'yaml' # bug in tmail 
require 'tmail'

def get_url(body)
  array = body.scan(/<a href="http:\/\/tira-teima\.as\.uol\.com\.br\/challengeSender\.html\?data=.*?" target=/)
  array.empty? ? nil : array[0][9..-10]
end

Net::POP3.start('imap.vexcorp.com', 110,
                'antispamuol@vexcorp.com', 'pee0theX') do |pop|
  if pop.mails.empty?
    puts 'No mail.'
  else
    pop.each_mail do |m|
      mail = TMail::Mail.parse(m.pop)

      next if !mail.friendly_from.match(/AntiSpam UOL/)

      puts get_url(mail.body)
    end
  end
end
