#!/usr/bin/ruby

require 'ccproto_client.rb'
require 'ftools'

HOST     = "api.decaptcher.com"
PORT     = 6905
#HOST     = "localhost"
#PORT     = 1010
USERNAME = "mtoledo"
PASSWORD = "a0m2s5d7j0g1"

def breakCaptcha(image)
  pict = image
  
  ccp = CCproto.new
  ccp.init

  puts "#" * 100 if DEBUG == true
  puts"Logging in..." if DEBUG == true
  puts "#" * 100 if DEBUG == true
  res = ccp.login(HOST, PORT, USERNAME, PASSWORD)
  if res < 0
    puts "FAILED" if DEBUG == true
  else
    puts " OK" if DEBUG == true
  end

  puts "#" * 100 if DEBUG == true
  puts "System load..." if DEBUG == true
  puts "#" * 100 if DEBUG == true

  res, system_load = ccp.system_load
  if res != CCERR_OK
    puts "system_load() FAILED" if DEBUG == true
    return
  end
  puts "System load=" + system_load.to_s + " perc" if DEBUG == true

  puts "#" * 100 if DEBUG == true
  puts "Balance..." if DEBUG == true
  puts "#" * 100 if DEBUG == true

  res, balance = ccp.balance
  if  res != CCERR_OK
    puts "balance() FAILED" if DEBUG == true
    return
  end
  puts "Balance=" + balance.to_s if DEBUG == true

  puts "#" * 100 if DEBUG == true
  puts "Picture..." if DEBUG == true
  puts "#" * 100 if DEBUG == true

  major_id = 0
  minor_id = 0
  for i in 1..3 do
    #pict = File.open(PIC_FILE_NAME, 'rb') { |f| f.read }
    text = ''
    puts "sending a picture..." if DEBUG == true

    pict_to      = PTODEFAULT
    pict_type    = PTUNSPECIFIED

    res, pict_to, pict_type, text, major_id, minor_id = ccp.picture2(pict)
    case res
      # most common return codes
    when CCERR_OK
      return text
      puts "got text for id=" + major_id.to_s + "/" + minor_id.to_s + ", type=" + pict_type.to_s + ", to=" + pict_to.to_s + ", text='" + text.to_s + "'" if DEBUG == true
      break

    when CCERR_BALANCE
      puts "not enough funds to process a picture, balance is depleted" if DEBUG == true
      break

    when CCERR_TIMEOUT
      puts "picture has been timed out on server (payment not taken)" if DEBUG == true
      break

    when CCERR_OVERLOAD
      puts "temporarily server-side error" if DEBUG == true
      puts " server's overloaded, wait a little before sending a new picture" if DEBUG == true
      break

      # local errors
    when CCERR_STATUS
      puts "local error." if DEBUG == true
      puts " either ccproto_init() or ccproto_login() has not been successfully called prior to ccproto_picture()" if DEBUG == true
      puts " need ccproto_init() and ccproto_login() to be called" if DEBUG == true
      break

      # network errors
    when ccERR_NET_ERROR
      puts "network troubles, better to call ccproto_login() again" if DEBUG == true
      break

      # server-side errors
    when ccERR_TEXT_SIZE
      puts "size of the text returned is too big" if DEBUG == true
      break

    when ccERR_GENERAL
      puts "server-side error, better to call ccproto_login() again" if DEBUG == true
      break
    when ccERR_UNKNOWN:
        puts " unknown error, better to call ccproto_login() again" if DEBUG == true
      break

    else
      # any other known errors?
      break
    end
  end
end

  #   # process a picture and if it is badly recognized
  #   # call picture_bad2() to name it as error.
  #   # pictures named bad are not charged

  #   #$ccp->picture_bad2( $major_id, $minor_id );
  # end

  # $balance = 0;
  # if( $ccp->balance( $balance ) != ccERR_OK ) {
  #     print( "balance() FAILED\n" );
  #     return;
  #   }
  #   print( "Balance=".$balance."\n" );

  #   $ccp->close();

  #   # also you can mark picture as bad after session is closed, but you need to be logged in again
  #   $ccp->init();
  #   print( "Logging in..." );
  #   if( $ccp->login( HOST, PORT, USERNAME, PASSWORD ) < 0 ) {
  #       print( " FAILED\n" );
  #       return;
  #     } else {
  #       print( " OK\n" );
  #     }
  #     print( "Naming picture ".$major_id."/".$minor_id." as bad\n" );
  #     $ccp->picture_bad2( $major_id, $minor_id );
  #     $ccp->close();
