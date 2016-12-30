# babyfengshui

## 0x1 Introduction

```
┌──[ root Hacked by Hawk1n5 at 50000-AntiVir-Linux in ~/ctf/33c3/pwn/baby ]
└─────> file babyfengshui 
babyfengshui: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, BuildID[sha1]=cecdaee24200fe5bbd3d34b30404961ca49067c6, stripped
┌──[ root Hacked by Hawk1n5 at 50000-AntiVir-Linux in ~/ctf/33c3/pwn/baby ]
└─────> checksec babyfengshui 
[*] Checking for new versions of pwntools
    To disable this functionality, set the contents of /root/.pwntools-cache/update to 'never'.
[*] A newer version of pwntools is available on pypi (3.2.0 --> 3.3.0).
    Update with: $ pip install -U pwntools
[*] '/root/ctf/33c3/pwn/baby/babyfengshui'
    Arch:     i386-32-little
    RELRO:    Partial RELRO
    Stack:    Canary found
    NX:       NX enabled
    PIE:      No PIE
```

this is a heap challenge，it have some feature:
```
0: Add a user
1: Delete a user
2: Display a user
3: Update a user description
4: Exit
Action: 
```
* 0: Add a user
    * scanf("%d",&size);
    * text = malloc(size);
    * name = malloc(0x80);
* 1: Delete a user
    * free(name)
    * free(text)
* 2: Display a user
    * printf("name: %s\n",name);
    * printf("description: %s\n",text);
* 3: Update a user description
    * modify text
* 4: Exit
    * quit...

## 0x1 Vulnerbility

if add user and update,when you want input text

```
text length: 1
text: b
```

it will ask text length,it look like:

```
scanf("%d",length);
if &name > &text+length
    read(0,text,length);
```

it check name address big then text address add length and it will read()

so if we do some operating :

```
def add_user(size,name,len,text)
add_user(10,"a",2,"a") # user0
add_user(10,"b",2,"b") # user1
delete(0)
add_user(128,"c",200,"c"*200) # user2
```

first we add two user,and then delete user0

text chunk will be fastbin,and name chunk will be unsorted bin.

and add user text size is 128 it will allocation unsorted bin chunk

name size will allocation after user1,it will look like this in heap:

```
------------
user2->text
------------
user1->text
------------
user1->name
------------
user2->name
------------
```

and look this judgment `if &name > &text+length`

now len can big to overwrite user1 chunk

next,can overwrite heap_array(0x804b080) and leak information

final hijack strchr.got and input sh will get shell!!!

[exploit](exp.rb)
