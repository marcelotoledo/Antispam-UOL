# imap.rb ---

# Copyright  (C)  2010  Marcelo Toledo <marcelo@marcelotoledo.com>

# Version: 1.0
# Keywords: 
# Author: Marcelo Toledo <marcelo@marcelotoledo.com>
# Maintainer: Marcelo Toledo <marcelo@marcelotoledo.com>
# URL: http://

# Commentary: 



# Code:

require 'net/imap'
require 'rubygems'
require 'yaml'
require 'tmail'

def get_url(body)
  array = body.scan(/<a href="http:\/\/tira-teima\.as\.uol\.com\.br\/challengeSender\.html\?data=.*?" target=/)
  array.empty? ? nil : array[0][9..-10]
end

# Source server connection info.
MAIL_NAME = 'imap.vexcorp.com'
MAIL_HOST = 'imap.vexcorp.com'
MAIL_PORT = 143
MAIL_SSL  = false
MAIL_USER = 'antispamuol@vexcorp.com'
MAIL_PASS = 'pee0theX'

# MAIL_NAME = 'imap.gmail.com'
# MAIL_HOST = 'imap.gmail.com'
# MAIL_PORT = 993
# MAIL_SSL  = true
# MAIL_USER = 'xxx@gmail.com'
# MAIL_PASS = 'xxxyyyzzz'

puts "Connecting..."
m = Net::IMAP.new(MAIL_HOST, MAIL_PORT, MAIL_SSL)

puts 'Logging in...'
m.login(MAIL_USER, MAIL_PASS)

puts "Going for INBOX..."
m.select('INBOX')

m.search(["ALL"]).each do |msg_id|
  msg = m.fetch(msg_id,'RFC822')[0].attr['RFC822']  
  mail = TMail::Mail.parse(msg)

  url = get_url(mail.body)  
  if !url
    puts "It's not Tira-Teima, marking for delete."
    m.store(msg_id, "+FLAGS", [:Deleted])
    next
  end
  
  puts url  
  p mail.subject
  p mail.friendly_from
  p mail.from
  p mail.to
  p mail.date
  p mail.body
end

puts "Expunging messages"
m.expunge

puts "Disconnecting"
m.disconnect
