require 'net/ftptls'

class OpenSSL::SSL::SSLSocket
  alias :read_nonblock :readpartial
end

class FtpsImplicit < Net::FTP
  FTP_PORT = 990

  def initialize(host=nil, user=nil, passwd=nil, acct=nil)
    super
    @passive = true
    @debug_mode = true
    @data_protection = 'P'
    @data_protected = false
  end
  attr_accessor :data_protection

  def open_socket(host, port, data_socket=false)
    puts "Opening socket to #{host}, #{port}"
    # sleep 30 if data_socket
    tcpsock = if defined? SOCKSsocket and ENV["SOCKS_SERVER"]
      @passive = true
      SOCKSsocket.open(host, port)
    else
      TCPSocket.new(host, port)
    end
    if !data_socket || @data_protection == 'P'
      # ssl_context.verify_mode = data_socket ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
      ssl_context = OpenSSL::SSL::SSLContext.new('SSLv23')
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ssl_context.key = nil
      ssl_context.cert = nil
      ssl_context.timeout = 10

      sock = OpenSSL::SSL::SSLSocket.new(tcpsock, ssl_context)
      puts "Connecting #{sock.inspect}..."
      sock.connect
      puts "Connected."
    else
      sock = tcpsock
    end
    # at_exit { sock.close; puts "ssl socket closed" }
    return sock
  end
  private :open_socket

  def connect(host, port=FTP_PORT)
    @sock = open_socket(host, port)
    mon_initialize
    getresp
    at_exit { puts "Quiting FTPS"; voidcmd("ABOR"); voidcmd("QUIT"); @sock.close }
  end

  def retrbinary(cmd, blocksize, rest_offset = nil) # :yield: data
    synchronize do
      voidcmd("TYPE I")
      conn = transfercmd(cmd, rest_offset)
      data = get_data(conn,blocksize)
      yield(data)
      voidresp
    end
  end

  def get_data(sock,blocksize=1024)
    timeout = 10
    starttime = Time.now
    buffer = ''
    puts "Getting data from socket #{sock}"
    timeouts = 0
    catch :done do
      loop do
        event = select([sock],nil,nil,0.5)
        if event.nil? # nil would be a timeout, we'd do nothing and start loop over. Of course here we really have no timeout...
          timeouts += 0.5
          break if timeouts > timeout
        else
          event[0].each do |sock| # Iterate through all sockets that have pending activity
            if sock.eof? # Socket's been closed by the client
              throw :done
            else
              buffer << sock.read_nonblock(blocksize)
              if block_given? # we're in line-by-line mode
                lines = buffer.split(/\r?\n/)
                buffer = buffer =~ /\n$/ ? '' : lines.pop
                lines.each do |line|
                  puts "Line: #{line}"
                  yield(line)
                end
              end
            end
          end
        end
      end
    end
    sock.close
    puts "Data: #{buffer}"
    buffer
  end

  def retrlines(cmd) # :yield: line
    synchronize do
      voidcmd("TYPE A")
      voidcmd("STRU F")
      voidcmd("MODE S")
      conn = transfercmd(cmd)
      get_data(conn) do |line|
        yield(line)
      end
      getresp
    end
  end

  def transfercmd(cmd, rest_offset=nil)
    unless @data_protected
      voidcmd('PBSZ 0')
      sendcmd("PROT #{@data_protection}")
      @data_protected = true
    end

    if @passive
      host, port = makepasv
      if @resume and rest_offset
        resp = sendcmd("REST " + rest_offset.to_s) 
        if resp[0] != ?3
          raise FTPReplyError, resp
        end
      end
      putline(cmd)
      conn = open_socket(host, port, true)
      resp = getresp
      if resp[0] != ?1
        raise FTPReplyError, resp
      end
    else
      sock = makeport
      if @resume and rest_offset
        resp = sendcmd("REST " + rest_offset.to_s) 
        if resp[0] != ?3
          raise FTPReplyError, resp
        end
      end
      resp = sendcmd(cmd)
      if resp[0] != ?1
        raise FTPReplyError, resp
      end
      conn = sock.accept
      sock.close
    end
    return conn
  end
  private :transfercmd
end
