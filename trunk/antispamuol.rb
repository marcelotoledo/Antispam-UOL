#!/usr/bin/ruby
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

Net::POP3.foreach('imap.vexcorp.com', 110,
                  'antispamuol@vexcorp.com', 'pee0theX') do |m|
  file.write m.pop
end
