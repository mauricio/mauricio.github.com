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

So we check the bytes we were given, if there's no CRLF, return and ask for more data, if there is one, return the byte 
array at the CRLF as that is a full message to be parsed. If there's no CRLF and we're at the end of the stream, fail as 
this is a broken stream, there should always be a CRLF, even if it's the last message.

Now we'll do some testing for the cases we have here:

```go
package redis

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestScanLines(t *testing.T) {
	tt := []struct {
		data []byte
		eof bool
		advance int
		token []byte
		err string
	} {
		{
			data: []byte("+PING\r\n"),
			advance: 7,
			token: []byte("+PING"),
		},
		{
			data: []byte("+PING"),
			eof: true,
			err: "incomplete stream: all redis messages should end with a CRLF but this line did not have it and we're at EOF, this is a broken stream: [+PING]",
		},
		{
			data: []byte("+PING"),
		},
		{
			data: []byte("+PING\r\n+PONG"),
			advance: 7,
			token: []byte("+PING"),
		},
	}

	for _, ts := range tt {
		t.Run(string(ts.data), func(t *testing.T) {
			advance, token, err := ScanLines(ts.data, ts.eof)
			assert.Equal(t, ts.advance, advance)
			assert.Equal(t, ts.token, token)
			if err != nil || ts.err != "" {
				assert.EqualError(t, err, ts.err)
			}
		})
	}
}
```

Now that we can find full messages on streams, we should start to parse full messages, we'll start with simple strings.
In RESP a simple string is a message that starts with `+` with everything after the `+` and until the CRLF being the value.

```
+PING\r\n
+PONG\r\n
```

These are both examples of simple strings. 