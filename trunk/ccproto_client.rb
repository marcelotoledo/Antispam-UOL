# ccproto_client.rb --- 

# Copyright  (C)  2010  Marcelo Toledo <marcelo@marcelotoledo.com>

# Version: 1.0
# Keywords: 
# Author: Marcelo Toledo <marcelo@marcelotoledo.com>
# Maintainer: Marcelo Toledo <marcelo@marcelotoledo.com>
# URL: http://

# Commentary: 



# Code:

require 'ccproto.rb'
require 'api_consts.rb'
require 'misc.rb'
require 'socket'
require 'digest'

SCCC_INIT  = 1   # initial status, ready to issue LOGIN on client
SCCC_LOGIN = 2   # LOGIN is sent, waiting for RAND (login accepted) or
                 # CLOSE CONNECTION (login is unknown)
SCCC_HASH = 3    # HASH is sent, server may CLOSE CONNECTION (hash is
                 # not recognized)
SCCC_PICTURE = 4

def breakCaptcha(pict)
  ccp = CCproto.new
  ccp.init

  pdebug "Logging in...\n"
  res = ccp.login(HOST, PORT, USERNAME, PASSWORD)
  raise LoginPasswordError if res < 0

  res, pict_to, pict_type, text, major_id, minor_id = ccp.picture2(pict)
  case res
    # most common return codes
  when CCERR_OK
    return text
    #pdebug "got text for id=" + major_id.to_s + "/" + minor_id.to_s + ", type=" + pict_type.to_s + ", to=" + pict_to.to_s + ", text='" + text.to_s + "'\n"
    break
    
  when CCERR_BALANCE
    raise CCERR_BALANCE, "not enough funds to process a picture, balance is depleted"

  when CCERR_TIMEOUT
    raise CCERR_TIMEOUT, "picture has been timed out on server (payment not taken)\n"

  when CCERR_OVERLOAD
    raise CCERR_OVERLOAD, "temporarily server-side error, server's overloaded, wait a little before sending a new picture"

    # local errors
  when CCERR_STATUS
    raise CCERR_STATUS, "local error. either ccproto_init() or ccproto_login() has not been successfully called prior to ccproto_picture() need ccproto_init() and ccproto_login() to be called"
    
    # network errors
  when CCERR_NET_ERROR
    raise CCERR_NET_ERROR, "network troubles, better to call ccproto_login() again"

    # server-side errors
  when CCERR_TEXT_SIZE
    raise CCERR_TEXT_SIZE, "size of the text returned is too big\n"

  when CCERR_GENERAL
    raise CCERR_GENERAL, "server-side error, better to call ccproto_login() again"

  when CCERR_UNKNOWN
    raise CCERR_UNKNOWN, "unknown error, better to call ccproto_login() again"

  else
    raise CCERR_UNKNOWN, "unknown error, better to call ccproto_login() again"    

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

class CCproto
  attr_accessor :status, :s

  def init
    @status = SCCC_INIT
  end

  def login(hostname, port, login, pwd)
    @status = SCCC_INIT
    
    @s = TCPSocket.open(hostname, port)
    
    pack = CC_packet.new
    pack.setVer(CC_PROTO_VER)
    
    pack.setCmd(CMDCC_LOGIN)
    pack.setSize(login.length)
    pack.setData(login)
    
    return CCERR_NET_ERROR if pack.packTo(@s) == false
    return CCERR_NET_ERROR if pack.unpackFrom(@s, CMDCC_RAND, CC_RAND_SIZE) == false

    shabuf = ''
    shabuf += pack.getData
    shabuf += Digest::MD5.hexdigest(pwd)
    shabuf += login

    pdebug "pack.getData -> ("+pack.getData+")"
    pdebug "MD5          -> ("+Digest::MD5.hexdigest(pwd)+")"
    pdebug "login        -> ("+login+")"
    pdebug "SHA256       -> ("+Digest::SHA256.hexdigest(pwd)+")"
    
    pack.setCmd(CMDCC_HASH)
    pack.setSize(CC_HASH_SIZE)    
    pack.setData(Digest::SHA256.digest(shabuf))
    
    return CCERR_NET_ERROR if pack.packTo(@s) == false
    return CCERR_NET_ERROR if pack.unpackFrom(@s, CMDCC_OK) == false

    @status = SCCC_PICTURE
    CCERR_OK
  end

  # pict: picture binary data
  # pict_to: timeout specifier to be used, on return - really used
  # specifier, see ptoXXX constants, ptoDEFAULT in case of
  # unrecognizable
  # pict_type: type specifier to be used, on return - really used
  # specifier, see ptXXX constants, ptUNSPECIFIED in case of
  # unrecognizable
  # text: text
  # major_id: OPTIONAL major part of the picture ID
  # minor_id: OPTIONAL minor part of the picture ID
  def picture2(pict, major_id = nil, minor_id = nil)
    return CCERR_STATUS if @status != SCCC_PICTURE

    pict_to   = PTODEFAULT
    pict_type = PTUNSPECIFIED
    
    pack = CC_packet.new
    pack.setVer(CC_PROTO_VER)
    pack.setCmd(CMDCC_PICTURE2)
    
    desc = CC_pict_descr.new
    desc.setTimeout(PTODEFAULT)
    desc.setType(pict_type)
    desc.setMajorID(0)
    desc.setMinorID(0)
    desc.setData(pict)
    desc.calcSize

    pack.setData(desc.pack)
    pack.calcSize
    
    return CCERR_NET_ERROR if pack.packTo(@s) == false
    return CCERR_NET_ERROR if pack.unpackFrom(@s) == false

    case pack.getCmd
    when CMDCC_TEXT2
      desc.unpack(pack.getData)
      pict_to    = desc.getTimeout
      pict_type  = desc.getType
      text       = desc.getData

      if major_id
        major_id = desc.getMajorID
      end

      if minor_id
        minor_id = desc.getMinorID
      end
      
      return CCERR_OK, pict_to, pict_type, text, major_id, minor_id

    when CMDCC_BALANCE
      # balance depleted
      return CCERR_BALANCE

    when CMDCC_OVERLOAD
      # server's busy
      return CCERR_OVERLOAD

    when CMDCC_TIMEOUT
      # picture timed out
      return CCERR_TIMEOUT

    when CMDCC_FAILED
      # server's error
      return CCERR_GENERAL

    else
      # unknown error
      return CCERR_UNKNOWN
    end
  end

  def picture_multipart
    puts "NOT IMPLEMENTED"
  end

  def picture_bad2(major_id, minor_id)
    pack = CC_packet.new

    pack.setVer(CC_PROTO_VER)
    pack.setCmd(CMDCC_PICTUREFL)

    desc = CC_pict_descr.new
    desc.setTimeout(PTODEFAULT)
    desc.setType(PTUNSPECIFIED)
    desc.setMajorID(major_id)
    desc.setMinorID(minor_id)
    desc.calcSize

    pack.setData(desc.pack)
    pack.calcSize

    if pack.packTo(@s) == false
      return CCERR_NET_ERROR
    end

    return CCERR_OK
  end

  def balance
    if @status != SCCC_PICTURE
      return CCERR_STATUS
    end

    pack = CC_packet.new
    pack.setVer(CC_PROTO_VER)
    pack.setCmd(CMDCC_BALANCE)
    pack.setSize(0)

    if pack.packTo(@s) == false
      return CCERR_NET_ERROR
    end

    if pack.unpackFrom(@s) == false
      return CCERR_NET_ERROR
    end

    case pack.getCmd
    when CMDCC_BALANCE
      balance = pack.getData
      return CCERR_OK, balance

    else
      # unknown error
      return CCERR_UNKNOWN
    end
  end

  def system_load
    return CCERR_STATUS if @status != SCCC_PICTURE

    pack = CC_packet.new
    pack.setVer(CC_PROTO_VER)
    pack.setCmd(CMDCC_SYSTEM_LOAD)
    pack.setSize(0)
    
    return CCERR_NET_ERROR if pack.packTo(@s) == false
    return CCERR_NET_ERROR if pack.unpackFrom(@s) == false
    return CCERR_UNKNOWN   if pack.getSize != 1

    case pack.getCmd
    when CMDCC_SYSTEM_LOAD
      arr = pack.getData.unpack('C')
      system_load = arr[0]
      return CCERR_OK, system_load

    else
      # unknown error
      return CCERR_UNKNOWN
    end
  end

  def close
    pack = CC_packet.new
    pack.setVer(CC_PROTO_VER)

    pack.setCmd(CMDCC_BYE)
    pack.setSize(0)


    return CCERR_NET_ERROR if pack.packTo(@s) == false
      
    @s.close
    @status = SCCC_INIT
    
    CCERR_NET_ERROR
  end
end
