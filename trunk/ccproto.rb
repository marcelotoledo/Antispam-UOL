CC_PROTO_VER        = 1      #  protocol version
CC_RAND_SIZE        = 256    #  size of the random sequence for authentication procedure
CC_MAX_TEXT_SIZE    = 100    #  maximum characters in returned text for picture
CC_MAX_LOGIN_SIZE   = 100    #  maximum characters in login string
CC_MAX_PICTURE_SIZE = 200000 #  200 K bytes for picture seems sufficient for all purposes
CC_HASH_SIZE        = 32

CMDCC_UNUSED      = 0
CMDCC_LOGIN       = 1  # login
CMDCC_BYE	  = 2  # end of session
CMDCC_RAND	  = 3  # random data for making hash with login+password
CMDCC_HASH	  = 4  # hash data
CMDCC_PICTURE	  = 5  # picture data, deprecated
CMDCC_TEXT	  = 6  # text data, deprecated
CMDCC_OK	  = 7  #
CMDCC_FAILED	  = 8  #
CMDCC_OVERLOAD	  = 9  #
CMDCC_BALANCE	  = 10 #  zero balance
CMDCC_TIMEOUT	  = 11 #  time out occured
CMDCC_PICTURE2	  = 12 #  picture data
CMDCC_PICTUREFL	  = 13 #  picture failure
CMDCC_TEXT2	  = 14 #  text data
CMDCC_SYSTEM_LOAD = 15 #  system load

SIZEOF_CC_PACKET     = 6
SIZEOF_CC_PICT_DESCR = 20

require 'api_consts.rb'

# packet class
class CC_packet
  attr_accessor :ver, :cmd, :size, :data

  def initialize
    @ver  = CC_PROTO_VER
    @cmd  = CMDCC_BYE
    @size = 0
    @data = ''
  end

  def checkPackHdr(cmd = nil, size = nil)
    puts "checkPackHdr: cmd = (" + cmd.to_s + ") size = (" + size.to_s + ")\n\n"
    
    if  @ver != CC_PROTO_VER
      return false
    end

    if cmd && @cmd != cmd
      return false
    end

    # TODO: no ultimo loop @size vem 0 e size nil
    if size && @size != size
      return false
    end
    
    true
  end
  
  # TODO: Checar se esta ok
  def pack
    print "pack(): "
    print [@ver, @cmd, @size].pack('CCV') + @data + "\n"
    print "(@ver = "
    print @ver
    print ")"
    print "(@cmd = "
    print @cmd
    print ")"
    print "(@size = "
    print @size
    print ")"
    print "(@data = "
    print @data
    print ")\n\n"
    
    [@ver, @cmd, @size].pack('CCV') + @data
  end
  
  # TODO: Checar se esta ok  
  def packTo(handle)
    handle.write(pack)
  end
  
  # TODO: Checar se esta ok
  def unpackHeader(bin)
    arr = bin.unpack('CCV')
    @ver  = arr[0]
    @cmd  = arr[1]
    @size = arr[2]

    puts "unpackHeader:"
    puts "bin = (" + bin + ")"
    print "arr = "
    p arr
    print "\n\n\n\n\n\n"
    print "(@ver: " + @ver.to_s + ")"
    print "(@cmd: " + @cmd.to_s + ")"
    print "(@size: " + @size.to_s + ")\n\n"
  end
  
  # TODO: Checar se esta ok  
  def unpackFrom(handle, cmd = nil, size = nil)
    bin = handle.recv(SIZEOF_CC_PACKET)
    
    puts "unpackFrom (" + SIZEOF_CC_PACKET.to_s + ")"
    puts "bin = (" + bin + ")"
    puts "CMD = ("+cmd.to_s+") size = ("+size.to_s+")\n\n"
    
    unpackHeader(bin)
    if checkPackHdr(cmd, size) == false
      return false
    end

    if @size > 0
      bin = handle.recv(@size)
      if bin == nil || bin == false
        return false
      end
      @data = bin
    end

    true
  end

  def setVer(ver)
    @ver = ver
  end

  def getVer
    @ver
  end

  def setCmd(cmd)
    @cmd = cmd
  end

  def getCmd(cmd)
    @cmd
  end

  def setSize(size)
    @size = size
  end

  def getSize
    @size
  end
  
  def calcSize
    @size = @data.length
    @size
  end

  def getFullSize
    SIZEOF_CC_PACKET + @size
  end

  def setData(data)
    @data = data
  end

  def getData
    @data
  end
end

# picture description class
class CC_pict_descr
  attr_accessor :timeout, :type, :size, :major_id, :minor_id, :data

  def initialize
    @timeout = PTODEFAULT
    @type    = PTUNSPECIFIED
    @size     = 0
    @major_id = 0
    @minor_id = 0
    @data     = nil
  end

  def pack
    [@timeout, @type, @size, @major_id, @minor_id].pack('VVVVV') + @data
  end
  
  # TODO: checar se esta ok
  def unpack(bin)
    arr = bin.unpack('VVVVV')
    @timeout  = arr[0]
    @type     = arr[1]
    @size     = arr[2]
    @major_id = arr[3]
    @minor_id = arr[4]
    @data     = bin[SIZEOF_CC_PICT_DESCR..bin.length]
  end
  
  def setTimeout(to)
    @timeout = to
  end
  
  def getTimeout
    @timeout
  end

  def setType(type)
    @type = type
  end
  
  def getType
    @type
  end
  
  def setSize(size)
    @size = size
  end
  
  def getSize
    @size
  end

  def calcSize
    @size = @data.length
    @size
  end
  
  def getFullSize
    SIZEOF_CC_PICT_DESCR + @size
  end
  
  def setMajorID(major_id)
    @major_id = major_id
  end

  def getMajorID
    @major_id
  end

  def setMinorID(minor_id)
    @minor_id = minor_id
  end

  def getMinorID
    @minor_id
  end    

  def setData(data)
    @data = data
  end

  def getData
    @data
  end
end
