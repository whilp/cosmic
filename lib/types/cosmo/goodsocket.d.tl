-- type declarations for cosmo.goodsocket

local record goodsocket
  AF_INET: number
  AF_INET6: number
  AF_UNIX: number
  AF_UNSPEC: number
  SOCK_STREAM: number
  SOCK_DGRAM: number
  SOCK_RAW: number
  SOCK_RDM: number
  SOCK_SEQPACKET: number
  IPPROTO_IP: number
  IPPROTO_TCP: number
  IPPROTO_UDP: number
  IPPROTO_ICMP: number
  IPPROTO_IPV6: number
  IPPROTO_ICMPV6: number
  IPPROTO_RAW: number

  --- Creates a socket with modern TCP optimizations enabled.
  --- This function wraps GoodSocket() which automatically enables performance
  --- features like TCP Fast Open, Quick ACK, and other optimizations based on
  --- whether you're creating a client or server socket.
  --- Example:
  --- local gs = require("cosmo.goodsocket")
  --- local unix = require("cosmo.unix")
  --- -- Create a TCP client socket
  --- local fd = assert(gs.socket(gs.AF_INET, gs.SOCK_STREAM, gs.IPPROTO_TCP, false))
  --- unix.close(fd)
  --- -- Create a TCP server socket with 30 second timeout
  --- local fd = assert(gs.socket(gs.AF_INET, gs.SOCK_STREAM, gs.IPPROTO_TCP, true, 30))
  --- unix.close(fd)
  socket: function(family: number, type: number, protocol: number, isserver: boolean, timeout?: number): number
end

return goodsocket

