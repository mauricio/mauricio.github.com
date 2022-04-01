---
layout: post
title: Building and distributing a command-line app in Go
keywords: cli, go
tags:
- useful
---

Thanks to its static binaries and cross-compiling, building and distributing command-line apps in Go is a breeze. You can quickly build an app and produce binaries for multiple platforms without leaving your current environment, and we'll learn how to do just that here.

We'll build a simple command-line HTTP client, produce binaries for Windows, Mac, and Linux and publish them to Github. [You can find the repo for this post here](https://github.com/mauricio/gurl).

We'll try to build this client by separating the actual command line operation from the rest of the code as much as we can, so to kick it off, let's look at the code that performs the HTTP request:

```go
type Config struct {
   Headers            http.Header
   UserAgent          string
   Data               string
   Method             string
   Insecure           bool
   Url                *url.URL
   ControlOutput      io.Writer
   ResponseBodyOutput io.Writer
}
```

The config type here encapsulates the options we offer for the command-line client in a way that is independent of who is making the calls. We allow it to set custom headers, user agent, request body data, HTTP method, if we allow requests to servers with certificates we don't trust, the URL called, and where we will print details of the process.

Next, the code that takes this config to execute the request:

```go
package gurl

import (
   "bytes"
   "crypto/tls"
   "fmt"
   "github.com/rs/zerolog/log"
   "io"
   "net/http"
   "net/url"
   "strings"
)

type Config struct {
   Headers            http.Header
   UserAgent          string
   Data               string
   Method             string
   Insecure           bool
   Url                *url.URL
   ControlOutput      io.Writer
   ResponseBodyOutput io.Writer
}

func Execute(c *Config) error {
   var r io.Reader
   var tlsConfig *tls.Config

   if c.Data != "" {
      r = bytes.NewBufferString(c.Data)
   }

   if c.Insecure {
      tlsConfig = &tls.Config{
         InsecureSkipVerify: true,
      }
   }

   request, err := http.NewRequest(c.Method, c.Url.String(), r)
   if err != nil {
      return err
   }

   if c.UserAgent != "" {
      request.Header.Set("User-Agent", c.UserAgent)
   }

   for key, values := range c.Headers {
      for _, value := range values {
         request.Header.Add(key, value)
      }
   }

   client := http.Client{
      Transport: &http.Transport{
         TLSClientConfig: tlsConfig,
      },
      CheckRedirect: func(req *http.Request, via []*http.Request) error {
         return http.ErrUseLastResponse
      },
   }

   requestBuilder := &wrappedBuilder{
      prefix: ">",
   }

   requestBuilder.Printf("%v %v", request.Method, request.URL.String())
   requestBuilder.WriteHeaders(request.Header)
   requestBuilder.Println()

   if _, err := io.Copy(c.ControlOutput, strings.NewReader(requestBuilder.String())); err != nil {
      return err
   }

   response, err := client.Do(request)
   if err != nil {
      return err
   }

   defer func() {
      if err := response.Body.Close(); err != nil {
         log.Warn().Err(err).Str("url", c.Url.String()).Msg("failed to close response body")
      }
   }()

   responseBuilder := &wrappedBuilder{
      prefix: "<",
   }

   responseBuilder.Printf("%v %v", response.Proto, response.Status)
   responseBuilder.WriteHeaders(response.Header)
   responseBuilder.Printf("")
   responseBuilder.Println()

   if _, err := io.Copy(c.ControlOutput, strings.NewReader(responseBuilder.String())); err != nil {
      return err
   }

   _, err = io.Copy(c.ResponseBodyOutput, response.Body)
   return err
}
```

Here we get the config object and set up the HTTP request and client objects to perform it. The code outputs general information to `ControlOutput` on the config (like what `curl` does by adding `<` and `>` to the output to see the outgoing and incoming data). This function doesn't care how it gets called, you can call it from a command-line operation or unit tests, and it still works the same way.

We also have a small helper object, the `wrappedBuilder`, to avoid repeating the prints (and simplify error handling, as it sucks to handle errors on every write to `ControlOutput`):

```go
type wrappedBuilder struct {
   prefix string
   strings.Builder
}

func (w *wrappedBuilder) WriteHeaders(headers http.Header) {
   for key, values := range headers {
      for _, value := range values {
         w.Printf("%v: %v", key, value)
      }
   }
}

func (w *wrappedBuilder) Println() {
   w.WriteString("\n")
}

func (w *wrappedBuilder) Printf(s string, a ...any) {
   w.WriteString(fmt.Sprintf("%v %v\n", w.prefix, fmt.Sprintf(s, a...)))
}
```

## Building the command line bridge

We'll use [cobra](https://github.com/spf13/cobra), one of the best command-line libraries available in Go, to parse the commands. In `cobra` everything is a `cobra.Command`, and you can have commands with subcommands (like `git status`, `status` here is a subcommand of `git`).

In our specific case, all we need is a single command, so here's how we'll build it:

```go
func CreateCommand() *cobra.Command {
   config := &Config{
      Headers:            map[string][]string{},
      ResponseBodyOutput: os.Stdout,
      ControlOutput:      os.Stdout,
   }

   headers := make([]string, 0, 255)

   command := &cobra.Command{
      Use:     `gurl URL`,
      Short:   `gurl is an HTTP client`,
      Long:    `gurl is an HTTP client for a tutorial on how to build command line clients in go`,
      Args:    ArgsValidator(config),
      PreRunE: OptionsValidator(config, headers),
      RunE: func(cmd *cobra.Command, args []string) error {
         return Execute(config)
      },
   }

   command.PersistentFlags().StringSliceVarP(&headers, "headers", "H", nil, `custom headers headers to be sent with the request, headers are separated by "," as in "HeaderName: Header content,OtherHeader: Some other value"`)
   command.PersistentFlags().StringVarP(&config.UserAgent, "user-agent", "u", "gurl", "the user agent to be used for requests")
   command.PersistentFlags().StringVarP(&config.Data, "data", "d", "", "data to be sent as the request body")
   command.PersistentFlags().StringVarP(&config.Method, "method", "m", http.MethodGet, "HTTP method to be used for the request")
   command.PersistentFlags().BoolVarP(&config.Insecure, "insecure", "k", false, "allows insecure server connections over HTTPS")

   return command
}
```

We start by creating a `Config` struct with the basic options setup (and pointing to `stdout`) and then create a `cobra.Command` with the options and documentation we need. You could add more examples and better documentation to the program here. It will be up to you how much you want to add, but the more, the merrier.

With the command created, we can now add flags. They are special options to change its behavior. These all point back to fields at the `Config` struct, so you can add more fields to it and then add flags to control the value here. One doesn't point directly, and it's the headers. Let's look at why that is:

```go
func OptionsValidator(c *Config, headers []string) func(cmd *cobra.Command, args []string) error {
   return func(cmd *cobra.Command, args []string) error {
      for _, h := range headers {
         if name, value, found := strings.Cut(h, ":"); found {
            c.Headers.Add(strings.TrimSpace(name), strings.TrimSpace(value))
         } else {
            return newErrorWithCode(3, "header is not a valid http header separated by `:`, value was: [%v]", h)
         }
      }

      return nil
   }
}
```

Unfortunately, `cobra` doesn't offer an easy way to parse `map[string][]string` from the command line (it does offer `map[string]string`, though). We use the `PreRunE` with the `OptionsValidator` function to parse the headers and add them to the `Headers` property at `Config`. If the header values are invalid, we return an error right away before calling the HTTP client code.

The other validation we have in place is for the arguments provided, the program requires a single argument to be called (as in `gurl http://example.com/`), so we verify there is exactly one parameter, and it is a valid URL before proceeding:

```go
func ArgsValidator(c *Config) func(cmd *cobra.Command, args []string) error {
   return func(cmd *cobra.Command, args []string) error {
      if l := len(args); l != 1 {
         return newErrorWithCode(2, "you must provide a single URL to be called but you provided %v", l)
      }

      u, err := url.Parse(args[0])
      if err != nil {
         return errors.Wrapf(err, "the URL provided is invalid: %v", args[0])
      }

      c.Url = u

      return nil
   }
}
```

With commands and implementation done, here's the main function that starts the program (this file lives at `cmd/gurl`):

```go
package main

import (
   "github.com/mauricio/gurl"
   "github.com/rs/zerolog"
   "os"
)

func main() {
   zerolog.TimeFieldFormat = zerolog.TimeFormatUnix

   if err := gurl.CreateCommand().Execute(); err != nil {
      switch e := err.(type) {
      case gurl.ReturnCodeError:
         os.Exit(e.Code())
      default:
         os.Exit(1)
      }
   }
}
```

It creates the command, runs it, checks the error, and exits. Here's the help it generates:

```shell
$   go run cmd/gurl/main.go -h
gurl is an HTTP client for a tutorial on how to build command line clients in go

Usage:
 gurl URL [flags]

Flags:
 -d, --data string     data to be sent as the request body
 -H, --headers strings   custom headers headers to be sent with the request, headers are separated by "," as in "HeaderName: Header content,OtherHeader: Some other value"
 -h, --help        help for gurl
 -k, --insecure      allows insecure server connections over HTTPS
 -m, --method string    HTTP method to be used for the request (default "GET")
 -u, --user-agent string  the user agent to be used for requests (default "gurl")
```

`cobra` formats and includes all the information we provided when setting up the command and flags. You don't even have to set up a `help` command. It just adds it automatically and prints the details.

## Building for multiple platforms

Now that we have all the pieces together, it's time to produce binaries for multiple platforms so we can distribute them. Now it's easier to [clone the repo](https://github.com/mauricio/gurl) to follow along, so you don't have to type everything.

If you don't have any native dependencies, you can cross-compile your `go` app to any supported platform. Here's what it looks like (all commands assume you have cloned the repo and are at the repo's root folder):

```shell
# building the program for intel macs
GOOS=darwin GOARCH=amd64 go build -o gurl-mac-amd64 cmd/gurl/main.go 
# building the program for M1 macs
GOOS=darwin GOARCH=amd64 go build -o gurl-mac-arm64 cmd/gurl/main.go 
# building the program for 64 bits amd/intel linux
GOOS=linux GOARCH=amd64 go build -o gurl-linux-amd64 cmd/gurl/main.go 
```

You can set the `GOOS` environment variable to multiple operating systems (like `Linux`, `windows`, `darwin`, and others) and the `GOARCH` to multiple architectures (like `amd64`, `arm64`, and others) and `go` will produce a binary for that specific version that you can use. So if you're working on a Linux box, you can make binaries for Macs and Windows without having a Mac or Windows box available. And users don't have to install virtual machines, language runtimes, or any other dependencies to run these programs. Build and send them the binaries, and they can be used right away.

To automate it to the next level, you can also use a tool like [goreleaser](https://goreleaser.com/) that can automatically build for multiple targets and even push the binaries as a release to GitHub, GitLab, or other source control repositories.

Golang's use of static binaries for its builds makes it an incredible tool to distribute command-line programs. You can build programs for multiple platforms from any platform, and they have no dependencies, making it a breeze to distribute them. Next time you're planning on building a tool like that, make sure you take a serious look at Go as its language.