---
layout: post
title: Why not build a Redis client in Golang? 
subtitle: Learn some networking basics and also how to communicate to a Redis server
keywords: go, redis, sockets, networking
tags:
- useful
---

Writing applications that talk to each other over the network is something we do almost daily but we usually don't worry too much about how the data moves along or what the communication protocol looks like, as we use HTTP clients and servers to do most of the work. Still, it's good to get dirty every once in a while with sockets and byte streams and learn a little about how we communicate with other applications. Today we're doing that with Redis.

First, why Redis? Redis is a widely used data structures store that has [a straightforward](https://redis.io/topics/protocol) protocol format we can cover in a single blog post but that is still very powerful in what it allows us to do. With Redis, you can deal with the common key-value store use case but you can also use other tools, like lists, sets, maps so the simplicity of the protocol also shows that you don't have to complicate the way you access data even if the implementation you might have on the server-side is indeed complex.

Our main goal here is to understand the basics of network programming in Go, write code that parses messages from and writes them to a Redis server and understand some options we have when writing apps that operate with sockets in the language. We are not going to cover optimizations, TCP/IP, or other advanced concepts, we're just going to write a simple Redis client. This client also doesn't work for Redis pub-sub, only for the general request-response interface.

[The full source code for this post is available on github](https://github.com/mauricio/redis-client).

# The protocol

The Redis wire protocol is what we usually call a terminator-based protocol as you know that a message has ended once you find a `\r\n`. For instance, if you want to define a *simple string* in Redis it's going to be written as:

```
+OK\r\n
```

The `+` marks this as a *simple string* and the content of the simple string is all the bytes until you find a `\r\n`. The other basic types are errors (`-ERR failed to do something\r\n`) and integers (`:1245\r\n`).

But what if the string you want to send has a `\r\n` in it, you might ask, this is where *bulk strings* some into place. This type is different than the others as it doesn't use the `\r\n` to mark the end alone but it also has a length of bytes that should be read as the value. Here's an example:

```
$6\r\ngolang\r\n
```

A *bulk string* stats with the `$` symbol, then a number as a string until a `\r\n` that is the length in bytes that you must read until you find another `\r\n` marking the end of the bulk string. Given we have the length we should read, it doesn't matter what are the contents inside the bulk string as we're not checking anything there, we're just reading everything until the end. So whenever you have to write a string that could have a `\r\n` in it you have to use bulk strings. Bulk strings have a special case that is a `null` bulk string, a bulk string with a `-1` length should be represented by clients as a `null` value and not an empty string, these are returned as `"$-1\r\n"`

And last but not least we have the *array* type that is a collection of the previously defined types (including arrays of arrays). They start with a `*` followed by an integer length (the number of items the array holds) and then each item in order, an array of two simple strings would look like `"*2\r\n+foo\r\n+bar\r\n"`, the `*2\r\n` piece says this is a two items array and then we get two simple strings. Any of the previously defined values are valid on arrays, including arrays themselves, if we wanted to have an array that is two separate arrays of simple strings we could define it like:

```
*2\r\n*3\r\n+foo\r\n+bar\r\n+sample\r\n*1\r\n+nope\r\n
```

Which would be equivalent to having:

```
[
    [ "foo", "bar", "sample"],
    ["nope"]
]
```

So you can mix and match values for arrays as you see fit. Arrays also have a special case, the `null` array, which just like the bulk string case is different from having an empty array in Redis, null arrays are defined as `*-1\r\n"`, an array with a `-1` length.

# Reading data

Now that we've covered the protocol basics, we'll start with the reader part of our implementation. Given we know this is mostly a terminator-based protocol (with only bulk strings as a special case) we can use a [bufio.Scanner](https://pkg.go.dev/bufio#Scanner) to parse the stream of data, breaking up the lines on `\r\n` and if we do see a bulk string do a bit more magic to return it to the code reading from the scanner as a single line.

When using a `bufio.Scanner` you provide a `SplitFunction` with the following signature:

```go
type SplitFunc func(data []byte, atEOF bool) (advance int, token []byte, err error)
```

So you get the data in bytes that are available and a `bool` value signaling if we're at the end of the stream or not. You then have to return how many bytes to advance on the stream, the data that should be returned to whoever is reading the scanner, and any error if it has happened. If you still don't have enough data to read, you just return a `nil` token value to ask the scanner to read more data (for instance, if there are no `\r\n` anywhere you know right away this isn't a full Redis response). Also, `atEOF` can be true and `data` not be empty, as you could be at the end of the stream because the server has closed the connection but it did write a full response back so even if you're at the end of a stream on a scanner you should make sure you check what the data is and return it to whoever is consuming from the scanner.

Our implementation here is done in two parts, one is the split function we use for the scanner, which breaks the Redis responses in lines, and the code that reads the lines, interprets them, and turns them into strings, integers, or arrays. Here's what it looks like:

```go
package redis_client

import (
	"bufio"
	"bytes"
	"encoding/base64"
	"errors"
	"fmt"
	pkgerrors "github.com/pkg/errors"
	"io"
	"strconv"
)

const (
	defaultBufferLength = 10140
	typeSimpleString    = '+'
	typeErorr           = '-'
	typeInteger         = ':'
	typeBulkString      = '$'
	typeArray           = '*'
)

var (
	separator = []byte("\r\n")
)

type Reader struct {
	scanner *bufio.Scanner
}

func NewReader(r io.Reader) *Reader {
	scanner := bufio.NewScanner(bufio.NewReaderSize(r, defaultBufferLength))
	scanner.Split(redisSplitter)

	return &Reader{
		scanner: scanner,
	}
}

func (r *Reader) Read() (*Result, error) {
	return readRESP(r.scanner)
}

// redisSplitter splits a byte stream into full lines in the redis protocol format. it reads a whole item
// (string, bulk string, error, integer, or array) and then returns it as a line. code reading from scanners
// created with this function can safely assume that if they got a line it's a full line that does not need
// any extra checking.
func redisSplitter(data []byte, atEOF bool) (advance int, token []byte, err error) {
	// a valid redis message has at least 3 characters, if less than that ask for more stuff
	if len(data) < 3 {

		if atEOF {
			return 0, nil, fmt.Errorf("unexpected end of stream, a redis message needs at least 3 characters to be valid, actual content in base64: [%v]", base64.RawStdEncoding.EncodeToString(data))
		}

		return 0, nil, nil
	}

	found := bytes.Index(data, separator)
	// if we could not find a \r\n and the stream is at its end, this stream is broken and can't be recovered
	if found == -1 && atEOF {
		return 0, nil, fmt.Errorf("unexpected end of stream, there should have been a \\r\\n before the end, actual content in base64: [%v]", base64.RawStdEncoding.EncodeToString(data))
	}

	// if there is no \r\n we need to read more data, this means this result isn't finished yet
	if found == -1 {
		return 0, nil, nil
	}

	// bulk strings are special, they change the binary format from a terminator based one (\r\n to close messages)
	// to a length based one. so once we figure out this message is a bulk string (like `$6\r\nfoobar\r\n`),
	// we have to read the length and make sure there are at least length + 2 bytes after the first \r\n to
	// show that we do have the whole bulk string here. it is not safe to just find all \r\n in a bulk string
	// because there could be \r\n tokens as part of the string itself, so we always have to make sure we consume
	// the length and use it to read the whole value.
	if data[0] == typeBulkString {
		length, err := strconv.ParseInt(string(data[1:found]), 10, 64)
		if err != nil {
			return 0, nil, fmt.Errorf("message starts as bulk string but length is not a valid int, actual content in base64: [%v]", base64.RawStdEncoding.EncodeToString(data[0:found]))
		}

		// a -1 length means this is a null string and should be returned as such to clients, null and empty
		// strings are different things in redis. this is the only time we return a bulk string sign ($) here
		// as we'll use it as a marker for null strings. for someone reading from a scanner
		// there should be no difference between a simple or a bulk string as we have already
		// parsed the lengh and we'll return only the actual string contents.
		if length == -1 {
			return 5, []byte("$"), nil
		}

		// a 0 length means an empty string, an empty string is not the same as a null string on redis
		if length == 0 {
			return 6, []byte("+"), nil
		}

		// this is the position of the first \r\n + the expected length + 4 which is the \r\n twice we have on bulk strings
		expectedEnding := found + int(length) + 4
		if len(data) >= expectedEnding {
			// given here we already have all the information we need to return this as a string,
			// we don't return the length anymore, we return this as if it was a normal string.
			// now we set the first `\n` we have to `+` so the code parses it as a simple string
			// as we have already capped the returned slice do the length of the string.

			start := found + 1
			data[start] = '+'
			return expectedEnding, data[start : expectedEnding-2], nil
		}

		if atEOF {
			return 0, nil, fmt.Errorf("unexpected end of stream, stream ends before bulk string has ended, expected there to be %v total bytes but there were only %v, actual content in base64: %v", expectedEnding, len(data), base64.RawStdEncoding.EncodeToString(data))
		}

		// not enough data, ask for more data to be read
		return 0, nil, err
	}

	return found + 2, data[:found], nil
}

// readRESP reads from a scanner that was initiated with `redisSplitter`. it expects every scanned line to be
// a full line of a data type redis supports (unless it's an array, arrays start with the length of the array only).
func readRESP(r *bufio.Scanner) (*Result, error) {

	for r.Scan() {
		line := r.Text()
		switch line[0] {
		case typeSimpleString:
			// if a string, just remove the marker and return it
			return &Result{
				content: line[1:],
			}, nil
		case typeBulkString:
			// a bulk string is only returned if it is nil, otherwise it is turned as a simple string
			return &Result{
				content: nil,
			}, nil
		case typeErorr:
			// if an error just wrap the error and return it
			return &Result{
				content: errors.New(line[1:]),
			}, nil
		case typeInteger:
			content, err := strconv.ParseInt(line[1:], 10, 64)
			if err != nil {
				return nil, fmt.Errorf("failed to parse returned integer: %v (value: %v)", err, line)
			}
			return &Result{
				content: content,
			}, nil
		case typeArray:
			// the first thing to be done when we find an array is to find its length, if not `-1` we then
			// read items from the scanner until we've read all items on the array.
			length, err := strconv.ParseInt(line[1:], 10, 64)
			if err != nil {
				return nil, fmt.Errorf("failed to parse array length: %v (value: %v)", err, line)
			}

			if length == -1 {
				return &Result{content: nil}, nil
			}

			contents := make([]interface{}, 0, length)

			for x := int64(0); x < length; x++ {
				result, err := readRESP(r)
				if err != nil {
					return nil, pkgerrors.Wrapf(err, "failed to read item %v from array", x)
				}

				contents = append(contents, result.content)
			}

			return &Result{
				content: contents,
			}, nil
		}
	}

	if r.Err() == nil {
		return nil, errors.New("scanner was empty")
	}

	return nil, r.Err()
}
```

Most of the complexity here lies at the `redisSplitter` function, that is breaking up the bytes into lines with a full item to be read. We also cheat a little on the bulk strings by turning them into simple strings on the fly. This is done mostly because we have the code that splits lines separate from the code that parses the values, if we weren't using a `bufio.Scanner` and were reading straight from the byte stream (the `io.Reader`) we could remove the special case for bulk strings but that would also require us to do a lot of the work that the scanner is doing. Doing it like this pushes the complexity of reading enough bytes and buffering them into the scanner instead of into our code.

We're also using this `Result` type here all over but it's just a wrapper to make it easier to transform a value from Redis if you know what it is supposed to be, here's the code:

```go
package redis_client

import "fmt"

type Result struct {
	content interface{}
}

func (r *Result) Err() error {
	err, ok := r.content.(error)
	if !ok {
		return nil
	}

	return err
}

func (r *Result) Int64() (int64, error) {
	if err := r.Err(); err != nil {
		return 0, err
	}

	result, ok := r.content.(int64)
	if !ok {
		return 0, fmt.Errorf("content is not an int64: %#v", r.content)
	}

	return result, nil
}

func (r *Result) String() (string, bool, error) {
	if err := r.Err(); err != nil {
		return "", false, err
	}

	if r.content == nil {
		return "", true, nil
	}

	result, ok := r.content.(string)
	if !ok {
		return "", false, fmt.Errorf("content is not an string: %#v", r.content)
	}

	return result, false, nil
}

func (r *Result) Slice() ([]interface{}, error) {
	if err := r.Err(); err != nil {
		return nil, err
	}

	if r.content == nil {
		return nil, nil
	}

	result, ok := r.content.([]interface{})
	if !ok {
		return nil, fmt.Errorf("content is not a slice: %#v", r.content)
	}

	return result, nil
}

func (r *Result) Content() interface{} {
	return r.content
}

```

It just holds the reponse that was read from redis and makes sure it is the right type before returning it.

# Writer

The writer is a simpler inverse version of the reader. Given we already know the protocol, what we have to do here is to write the data in the correct format:

```go
package redis_client

import (
	"encoding/base64"
	"fmt"
	"github.com/pkg/errors"
	"io"
	"strconv"
)

type Writer struct {
	writer io.Writer
}

func NewWriter(w io.Writer) *Writer {
	return &Writer{
		writer: w,
	}
}

func (w *Writer) write(messageType byte, contents ...[]byte) error {
	if _, err := w.writer.Write([]byte{messageType}); err != nil {
		return errors.Wrapf(err, "failed to write message type: %v", messageType)
	}

	for _, b := range contents {
		if _, err := w.writer.Write(b); err != nil {
			return errors.Wrapf(err, "failed to write bytes, content in base64: [%v]", base64.RawStdEncoding.EncodeToString(b))
		}
	}

	return nil
}

func (w *Writer) WriteBulkString(value []byte) error {
	return w.write(
		typeBulkString,
		[]byte(strconv.FormatInt(int64(len(value)), 10)),
		separator,
		value,
		separator,
	)
}

// WriteNil writes a nil bulk string
func (w *Writer) WriteNil() error {
	return w.write(typeBulkString, []byte("-1"), separator)
}

func (w *Writer) WriteInt64(v int64) error {
	return w.write(
		typeInteger,
		[]byte(strconv.FormatInt(v, 10)),
		separator)
}

// WriteArray writes an array that contains int8 to int64, strings, []byte, []interface{} or nil.
// Any other values inside the array will cause this method to return an error.
func (w *Writer) WriteArray(values []interface{}) error {
	if values == nil {
		return w.write(typeArray, []byte("-1"), separator)
	}

	if err := w.write(
		typeArray,
		[]byte(strconv.FormatInt(int64(len(values)), 10)),
		separator,
	); err != nil {
		return err
	}

	for _, v := range values {
		switch t := v.(type) {
		case int8:
			if err := w.WriteInt64(int64(t)); err != nil {
				return err
			}
		case int16:
			if err := w.WriteInt64(int64(t)); err != nil {
				return err
			}
		case int:
			if err := w.WriteInt64(int64(t)); err != nil {
				return err
			}
		case int32:
			if err := w.WriteInt64(int64(t)); err != nil {
				return err
			}
		case int64:
			if err := w.WriteInt64(t); err != nil {
				return err
			}
		case string:
			if err := w.WriteBulkString([]byte(t)); err != nil {
				return err
			}
		case []byte:
			if err := w.WriteBulkString(t); err != nil {
				return err
			}
		case []interface{}:
			if err := w.WriteArray(t); err != nil {
				return err
			}
		case nil:
			if err := w.WriteNil(); err != nil {
				return err
			}
		default:
			return fmt.Errorf("unsupported type: the value [%#v] is not supported by this client, supported types are int8 to int64, strings, []byte, nil, and []interface{} of these same types", v)
		}
	}

	return nil
}
```

Our writer is a bit strict, it only writes numbers from int8 to int64, strings and arrays with the previous values. We also don't bother with writing simple strings at all, we just assume all strings are always bulk strings as that allows us to ignore if there is a `\r\n` at all inside of them and just write them with the length directly. We also introduce methods to write `null` strings and `null` arrays as those are both valid values for redis.

# The client

So we can read and write the Redis protocol from streams of bytes, the last step is to actually create a client that can open a socket connection given an address and talk to Redis, here's what it would look like:

```go
package redis_client

import (
	"context"
	"github.com/pkg/errors"
	"io"
	"net"
	"time"
)

var (
	_ io.Closer = &Client{}
)

type Client struct {
	conn   net.Conn
	reader *Reader
	writer *Writer
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) Send(values []interface{}) (*Result, error) {
	c.conn.SetDeadline(time.Now().Add(time.Second * 5))

	if err := c.writer.WriteArray(values); err != nil {
		return nil, errors.Wrapf(err, "failed to execute operation: %v", values[0])
	}

	return c.reader.Read()
}

func Connect(ctx context.Context, address string) (*Client, error) {
	dialer := net.Dialer{
		Timeout:   time.Second * 5,
		KeepAlive: time.Second * 10,
	}

	conn, err := dialer.DialContext(ctx, "tcp4", address)
	if err != nil {
		return nil, errors.Wrapf(err, "failed to connect to %v", address)
	}

	return &Client{
		conn:   conn,
		reader: NewReader(conn),
		writer: NewWriter(conn),
	}, nil
}
```

Given we've done most of the actual protocol parsing work at the `Reader` and `Writer` structs the only thing this client does is to create a dialer and open the TCP connection to Redis. The important pieces here are to make sure you setup a timeout on the dialer and a deadline on every operation. Here we're just hardcoding a 5 seconds deadline on every read/write but you can make this configurable, what is important here is to make sure that we do have timeouts/deadlines configured on every operations so we don't wait forever or until an error happens on the connection to give up the operation.

And with this you have a fully functional redis client that can send and receive any commands from the server. We built it by creating separate structs for the different operaitons we need (reading and writing) and when composed them into the actual client. By building them as separate pieces we can easily write unit tests for them ([check the repo for the tests](https://github.com/mauricio/redis-client)) and then assemble them into the actual client, this simplifies development and even allows us to build upon these as needed, we could, for instance, create a pooling client that holds onto multiple connections and the only piece that would change is the client itself, the reader and writer code would stay the same, thus requiring less code to be written. Now off you go building more clients for the apps you use!