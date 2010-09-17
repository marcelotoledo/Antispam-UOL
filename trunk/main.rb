# -*- coding: utf-8 -*-
# main.rb --- 

# Copyright  (C)  2010  Marcelo Toledo <marcelo@marcelotoledo.com>

# Version: 1.0
# Keywords: 
# Author: Marcelo Toledo <marcelo@marcelotoledo.com>
# Maintainer: Marcelo Toledo <marcelo@marcelotoledo.com>
# URL: http://

# Commentary: 



# Code:

#!/usr/bin/ruby

require 'ccproto_client.rb'
require 'api_consts.rb'
require 'misc.rb'
require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'net/pop'
require 'yaml' # bug in tmail 
require 'tmail'

def get_url(body)
  array = body.scan(/<a href="http:\/\/tira-teima\.as\.uol\.com\.br\/challengeSender\.html\?data=.*?" target=/)
  array.empty? ? nil : array[0][9..-10]
end

while true do
  Net::POP3.start(MAIL_SERVER, MAIL_PORT, MAIL_USER, MAIL_PASS) do |pop|
    if pop.mails.empty?
      puts 'No mail. Sleeping...'
      sleep(MAIL_RETRY)
    else
      pop.each_mail do |m|
        mail = TMail::Mail.parse(m.pop)


        if !mail.friendly_from.match(/AntiSpam UOL/)
          puts "This email is not from UOL Tira Teima. Deleting."
          m.delete
          next
        end
        
        url = get_url(mail.body)
        agent = Mechanize.new
        page = agent.get(url)
        
        pict = ''
        page.images.each do |img|
          if img.src.match('n.tt.uol.com.br')
            puts img.src
            pict = open(img.src) { |f| f.read }
            break
          end
        end
        
        begin
          captcha = breakCaptcha(pict)
        rescue
          puts "Erro ao quebrar captcha"
        end
        
        puts "CAPTCHA quebrado = ("+captcha+")" unless captcha.nil?
        
        img = File.new('hello.jpg', 'w')
        img.write(pict)
        img.close
        
        f = page.form('envia')
        f.WORD_KEY = captcha
        page = agent.submit(f, f.buttons.first)
        if page.body.match('The message you sent has been confirmed')
          puts "Mensagem liberada! Removing from queue."
          m.delete
        else
          puts "Não liberada. Reagendada para próxima tentativa."
        end
      end
    end
  end
end
