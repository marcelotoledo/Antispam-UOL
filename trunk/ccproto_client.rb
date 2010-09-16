require 'ccproto.rb'
require 'api_consts'

require 'socket'
require 'digest'

SCCC_INIT  = 1   # initial status, ready to issue LOGIN on client
SCCC_LOGIN = 2   # LOGIN is sent, waiting for RAND (login accepted) or
                 # CLOSE CONNECTION (login is unknown)
SCCC_HASH = 3    # HASH is sent, server may CLOSE CONNECTION (hash is
                 # not recognized)
SCCC_PICTURE = 4 

# CC protocol class
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

    if pack.packTo(@s) == false
      s.close
      return CCERR_NET_ERROR
    end

    if pack.unpackFrom(@s, CMDCC_RAND, CC_RAND_SIZE) == false
      s.close
      return CCERR_NET_ERROR
    end

    shabuf = ''
    shabuf += pack.getData
    shabuf += Digest::MD5.hexdigest(pwd)
    #shabuf += Digest::MD5.digest(pwd)
    shabuf += login

    puts "pack.getData -> ("+pack.getData+")"
    puts "MD5          -> ("+Digest::MD5.hexdigest(pwd)+")"
    puts "login        -> ("+login+")"
    puts "SHA256       -> ("+Digest::SHA256.hexdigest(pwd)+")"
    
    pack.setCmd(CMDCC_HASH)
    pack.setSize(CC_HASH_SIZE)    
    #pack.setData(Digest::SHA256.hexdigest(shabuf))
    pack.setData(Digest::SHA256.digest(shabuf))

    if pack.packTo(@s) == false
      s.close
      return CCERR_NET_ERROR
    end
    
    # TODO: Erro aqui
    if pack.unpackFrom(@s, CMDCC_OK) == false
      s.close
      return CCERR_NET_ERROR
    end

    @status = SCCC_PICTURE

    return CCERR_OK
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
    if @status != SCCC_PICTURE
      return CCERR_STATUS
    end

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

    if pack.packTo(@s) == false
      return CCERR_NET_ERROR
    end

    if pack.unpackFrom(@s) == false
      return CCERR_NET_ERROR
    end

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
        #return CCERR_OK, pict_to, pict_type, text, major_id, minor_id
      end
      
      # TODO: Aqui ou dentro do if minor_id
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
    if @status != SCCC_PICTURE
      return CCERR_STATUS
    end

    pack = CC_packet.new
    pack.setVer(CC_PROTO_VER)
    pack.setCmd(CMDCC_SYSTEM_LOAD)
    pack.setSize(0)

    if pack.packTo(@s) == false
      return CCERR_NET_ERROR
    end

    if pack.unpackFrom(@s) == false
      return CCERR_NET_ERROR
    end

    if pack.getSize != 1
      return CCERR_UNKNOWN
    end

    case pack.getCmd
    when CMDCC_SYSTEM_LOAD
      arr = pack.getData.unpack('C')
      #arr = unpack('C', pack.getData)
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
    
    if pack.packTo(@s) == false
      return CCERR_NET_ERROR
    end

    @s.close
    @status = SCCC_INIT
    
    return CCERR_NET_ERROR
  end
end

