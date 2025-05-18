import Socket

open Socket

/--
\ Serve
-/
partial def talkToSocket (addr : SockAddr) (socket' : Socket) : IO Unit := do
  let incoming <- String.fromUTF8! <$> socket'.recv 1024
  match incoming.length with
  -- End the server
    | Nat.zero => 
      IO.println s!"Close connection to {addr}!"
      socket'.close
  -- Loop the server
    | _ => do 
      let strSend := "HTTP/1.1 200 OK\r\n" ++ s!"Content-Length:{incoming.length}" ++ "\r\n\r\n" ++ incoming ++ "\r\n\r\n"
      let bytesSend ← socket'.send strSend.toUTF8
      IO.println s!"sent {bytesSend} bytes"
      talkToSocket addr socket'

/--
  Entry
-/
def main : IO Unit := do
  -- configure local SockAddr
  let localAddr ← SockAddr.mk "localhost" "8080" AddressFamily.inet SockType.stream
  IO.println s!"Local Addr: {localAddr}"

  -- bind a socket to local address
  let socket ← Socket.mk AddressFamily.inet SockType.stream
  socket.bind localAddr
  IO.println "Socket Bound."

  -- listen to HTTP requests
  socket.listen 5
  IO.println s!"Listening at http://localhost:8080."

  -- serving
  repeat do
    let (remoteAddr, socket') ← socket.accept
    IO.println s!"Incoming request from {remoteAddr}"
    let output ←  IO.asTask $ talkToSocket remoteAddr socket'
