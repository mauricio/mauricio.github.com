---
layout: post
title: Building a redis client from scratch in Go
subtitle: and doing sockets while at it
keywords: golang, redis, networking, sockets
tags:
- useful
---

Got myself into some work that required parsing Redis messages and it felt like a nice topic to talk a bit about application
network protocols. The Redis protocol, called [RESP (REdis Serialization Protocol)](https://redis.io/topics/protocol), is a 
powerful yet simple communication protocol that's easy to implement, so lets take a look at how we could go about building
a Redis client in Go.

The basic rule for the redis protocol is that the messages are comprised of a type of message in the first byte and then
content until you find a `\r\n` (we'll get to the special case later). So we quickly figure out that we have to split all
the data we get every `\r\n` to return a full message to be parsed. We could just build something that splits byte streams
whenever it finds a `\r\n` manually but golang offers a class just for that, [bufio.Scanner](https://golang.org/pkg/bufio/#Scanner).
The scanner takes a split function as a parameter and does the work of reading through the stream and splitting it for you so 
we'll start by building a simple split function:

```go
package redis

import (
	"bytes"
	"fmt"
)

var (
	crlfBytes = []byte{'\r','\n'}
)

func ScanLines(data []byte, atEOF bool) (advance int, token []byte, err error) {
	// empty array, ask for more data
	if len(data) == 0 {
		return 0, nil, nil
	}

	nextCrlf := bytes.Index(data, crlfBytes)

	if nextCrlf >= 0 {
		// here's a full crlf-terminated line.
		return nextCrlf + 2, data[0:nextCrlf], nil
	}
	// If we're at EOF and there's no crlf, this is a broken stream, error it
	if atEOF {
		return 0, nil, fmt.Errorf("incomplete stream: all redis messages should end with a CRLF but this line did not have it and we're at EOF, this is a broken stream: [%v]", string(data))
	}

	// need more data
	return 0, nil, nil
}
```
