---
layout: post
title: Rate limiting HTTP requests in Go using Redis
subtitle: protecting your API
keywords: go, http, redis, rate limiting
tags:
- useful
---

So you've created this awesome API, that offers a feature a lot of customers would be interested in using, but they're using it so much you can't handle the load in an effective way for everyone. While scaling up and making the service more reliable is an option, just doing that is not enough, the load might be uneven, the usage patterns might not be what your application was made to handle or you might just have limits you can't fix at this point in time, that's where rate-limiting comes in.

The idea behind rate limiting is that you're going to have a maximum amount of requests you'll be taking from a client and once that limit is reached, over a defined period, you'll start dropping requests until you reach the end of the period and restart the counter. For instance, clients are allowed to make 60 requests every minute, once they go over 60 requests you start denying the requests letting them know they're over their quota and need to wait to continue to have their requests served again.

The goal here is to make *your service* more reliable, rate-limiting is a protection you implement on your side to make sure bad actors or misconfigured clients can't take the whole service down or cause outages because the service is going over its expected usage limits. In an ideal scenario, you're not punishing good clients, as you have given them enough requests to do their usual work, but you'd block bad clients from wreaking havoc on your service.

You can find the whole source code for the project we'll be discussing below [here on Github](https://github.com/mauricio/redis-rate-limiter).

## Building a rate-limiter

We'll have multiple implementations for the rate limiter to discuss the pros and cons of the different implementations, let's start then with the stuff that will be common across the implementations:

```go
package redis_rate_limiter

import (
	"context"
	"time"
)

// Request defines a request that needs to be checked if it will be rate-limited or not.
// The `Key` is the identifier you're using for the client making calls. This could be a user/account ID if the user is
// signed into your application, the IP of the client making requests (this might not be reliable if you're not behind a
// proxy like Cloudflare, as clients can try to spoof IPs). The `Key` should be the same for multiple calls of the
// same client so we can correctly identify that this is the same app calling anywhere.
// `Limit` is the number of requests the client is allowed to make over the `Duration` period. If you set this to
// 100 and `Duration` to `1m` you'd have at most 100 requests over a minute.
type Request struct {
	Key      string
	Limit    uint64
	Duration time.Duration
}

// State is the result of evaluating the rate limit, either `Deny` or `Allow` a request.
type State int64

const (
	Deny  State = 0
	Allow       = 1
)

// Result represents the response to a check if a client should be rate-limited or not. The `State` will be either
// `Allow` or `Deny`, `TotalRequests` holds the number of requests this specific caller has already made over
// the current period and `ExpiresAt` defines when the rate limit will expire/roll over for clients that
// have gone over the limit.
type Result struct {
	State         State
	TotalRequests uint64
	ExpiresAt     time.Time
}

// Strategy is the interface the rate limit implementations must implement to be used, it takes a `Request` and
// returns a `Result` and an `error`, any errors the rate-limiter finds should be bubbled up so the code can make a
// decision about what it wants to do with the request.
type Strategy interface {
	Run(ctx context.Context, r *Request) (*Result, error)
}
```

## A counter-based implementation

So we have the basics in place, what is the input, the output, and a small interface that needs to be implemented by every counter, let's look at the first counter, that just uses counters on Redis:

```go
package redis_rate_limiter

import (
	"context"
	"github.com/go-redis/redis/v8"
	"github.com/pkg/errors"
	"time"
)

var (
	_ Strategy = &counterStrategy{}
)

const (
	keyWithoutExpire = -1
)

func NewCounterStrategy(client *redis.Client, now func() time.Time) *counterStrategy {
	return &counterStrategy{
		client: client,
		now:    now,
	}
}

type counterStrategy struct {
	client *redis.Client
	now    func() time.Time
}

// Run this implementation uses a simple counter with an expiration set to the rate limit duration.
// This implementation is functional but not very effective if you have to deal with bursty traffic as
// it will still allow a client to burn through its full limit quickly once the key expires.
func (c *counterStrategy) Run(ctx context.Context, r *Request) (*Result, error) {
	// a pipeline in Redis is a way to send multiple commands that will all be run together.
	// this is not a transaction and there are many ways in which these commands could fail
	// (only the first, only the second) so we have to make sure all errors are handled, this
	// is a network performance optimization.

	p := c.client.Pipeline()
	incrResult := p.Incr(ctx, r.Key)
	ttlResult := p.TTL(ctx, r.Key)

	if _, err := p.Exec(ctx); err != nil {
		return nil, errors.Wrapf(err, "failed to execute increment to key %v", r.Key)
	}

	totalRequests, err := incrResult.Result()
	if err != nil {
		return nil, errors.Wrapf(err, "failed to increment key %v", r.Key)
	}

	var ttlDuration time.Duration

	// we want to make sure there is always an expiration set on the key, so on every
	// increment we check again to make sure it has a TTl and if it doesn't we add one.
	// a duration of -1 means that the key has no expiration so we need to make sure there
	// is one set, this should, most of the time, happen when we increment for the
	// first time but there could be cases where we fail at the previous commands so we should
	// check for the TTL on every request.
	if d, err := ttlResult.Result(); err != nil || d == keyWithoutExpire {
		ttlDuration = r.Duration
		if err := c.client.Expire(ctx, r.Key, r.Duration).Err(); err != nil {
			return nil, errors.Wrapf(err, "failed to set an expiration to key %v", r.Key)
		}
	} else {
		ttlDuration = d
	}

	expiresAt := c.now().Add(ttlDuration)

	requests := uint64(totalRequests)

	if requests > r.Limit {
		return &Result{
			State:         Deny,
			TotalRequests: requests,
			ExpiresAt:     expiresAt,
		}, nil
	}

	return &Result{
		State:         Allow,
		TotalRequests: requests,
		ExpiresAt:     expiresAt,
	}, nil
}
```

This implementation is what would usually be called a *fixed window strategy*, it means that once the expiration has been set, a client that reaches the limit will be blocked from making further requests until the expiration time arrives. If a client has a limit of 50 requests every minute and makes all 50 requests in the first 5 seconds of the minute, it will have to wait 55 seconds to make another request. This is also the main downside of this implementation, it would still let a client burn through its whole limit quickly (bursty traffic) and that could still overload your service, as it could be expecting this traffic to be spread out throughout the whole limiting period.

## A sorted set implementation to react better to bursty traffic

A *rolling window strategy* offers better protection for bursty traffic as it doesn't reset the counter completely but keeps the history for the duration of the time window. If you have a 5 minutes window, it will always count the amount of traffic that was generated over the last 5 minutes to decide if a client should be blocked or not instead of just waiting for a key to expire. This implementation is more CPU and memory intensive as you have to keep more information in memory(every request with its timestamp) but provides better protection against quick bursts of traffic.

Here's what it looks like:

```go
package redis_rate_limiter

import (
	"context"
	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
	"github.com/pkg/errors"
	"strconv"
	"time"
)

var (
	_ Strategy = &sortedSetCounter{}
)

func NewSortedSetCounterStrategy(client *redis.Client, now func() time.Time) Strategy {
	return &sortedSetCounter{
		client: client,
		now:    now,
	}
}

type sortedSetCounter struct {
	client *redis.Client
	now    func() time.Time
}

// Run this implementation uses a sorted set that holds a UUID for every request with a score that is the
// time the request has happened. This allows us to delete events from *before* the current window if the window
// is 5 minutes, we want to remove all events from before 5 minutes ago, this way we make sure we roll old
// requests off the counters creating a rolling window for the rate limiter. So, if your window is 100 requests
// in 5 minutes and you spread the load evenly across the minutes, once you hit 6 minutes the requests you made
// on the first minute have now expired but the other 4 minutes of requests are still valid.
// A rolling window counter is usually never 0 if traffic is consistent so it is very effective at preventing
// bursts of traffic as the counter won't ever expire.
func (s *sortedSetCounter) Run(ctx context.Context, r *Request) (*Result, error) {
	now := s.now()
	// every request needs an UUID
	item := uuid.New()

	minimum := now.Add(-r.Duration)

	p := s.client.Pipeline()

	// we then remove all requests that have already expired on this set
	removeByScore := p.ZRemRangeByScore(ctx, r.Key, "0", strconv.FormatInt(minimum.UnixMilli(), 10))

	// we add the current request
	add := p.ZAdd(ctx, r.Key, &redis.Z{
		Score:  float64(now.UnixMilli()),
		Member: item.String(),
	})

	// count how many non-expired requests we have on the sorted set
	count := p.ZCount(ctx, r.Key, "-inf", "+inf")

	if _, err := p.Exec(ctx); err != nil {
		return nil, errors.Wrapf(err, "failed to execute sorted set pipeline for key: %v", r.Key)
	}

	if err := removeByScore.Err(); err != nil {
		return nil, errors.Wrapf(err, "failed to remove items from key %v", r.Key)
	}

	if err := add.Err(); err != nil {
		return nil, errors.Wrapf(err, "failed to add item to key %v", r.Key)
	}

	totalRequests, err := count.Result()
	if err != nil {
		return nil, errors.Wrapf(err, "failed to count items for key %v", r.Key)
	}

	expiresAt := now.Add(r.Duration)
	requests := uint64(totalRequests)

	if requests > r.Limit {
		return &Result{
			State:         Deny,
			TotalRequests: requests,
			ExpiresAt:     expiresAt,
		}, nil
	}

	return &Result{
		State:         Allow,
		TotalRequests: requests,
		ExpiresAt:     expiresAt,
	}, nil
}
```

The goal here is to use the sorted set with the current timestamp for the request as the sorting key so we can quickly ask for all requests under a specific time range to be deleted, cleaning up requests that were already expired. As we're using an UUID as the value the odds we'll have these requests conflict with each other on the sorted set are very low and having a conflict every once in a while wouldn't be too much trouble, even with millions of requests being served.

## Write heavy solutions

Both implementations here are *write first*, they first write stuff into Redis and then check if the request should be accepted or not. While this makes the code more straightforward and produces less network traffic from the client to the server, they make it much more expensive for the server to operate, as it is always writing something and changing data in memory, even *unbounded data*, as in the sorted set case. We're not making sure these sorted sets are cleaned up or that there is a limit on how many requests can be stored and this is a general red flag you should not let happen on the systems you're working on.

We have to make sure the resource usage here is *bounded*, that is, it has a well known limit, you should always assume anything you're writing is going to be abused in some way (either intentionally or by accident) and make sure that your code forces a bound on these resources in some way. On Redis itself, there are many ways to make sure you're not going to run out of memory by setting a [maxmemory](https://github.com/redis/redis/blob/ae2f5b7b2e007e4bb7108407d7d41972312d0766/redis.conf#L1071) value for how much memory it can use and [maxmemory-policy](https://github.com/redis/redis/blob/ae2f5b7b2e007e4bb7108407d7d41972312d0766/redis.conf#L1100) to a value that is not `no-eviction`. For a rate limiter like the one we're building here `allkeys-lru` is a pretty decent option.

## Bounded counter implementations

The updated counter implementation with a read before write would look like this:

```go
package redis_rate_limiter

import (
	"context"
	"github.com/go-redis/redis/v8"
	"github.com/pkg/errors"
	"time"
)

var (
	_ Strategy = &counterStrategy{}
)

const (
	keyThatDoesNotExist = -2
	keyWithoutExpire    = -1
)

func NewCounterStrategy(client *redis.Client, now func() time.Time) *counterStrategy {
	return &counterStrategy{
		client: client,
		now:    now,
	}
}

type counterStrategy struct {
	client *redis.Client
	now    func() time.Time
}

// Run this implementation uses a simple counter with an expiration set to the rate limit duration.
// This implementation is functional but not very effective if you have to deal with bursty traffic as
// it will still allow a client to burn through its full limit quickly once the key expires.
func (c *counterStrategy) Run(ctx context.Context, r *Request) (*Result, error) {

	// a pipeline in redis is a way to send multiple commands that will all be run together.
	// this is not a transaction and there are many ways in which these commands could fail
	// (only the first, only the second) so we have to make sure all errors are handled, this
	// is a network performance optimization.

	// here we try to get the current value and also try to set an expiration on it
	getPipeline := c.client.Pipeline()
	getResult := getPipeline.Get(ctx, r.Key)
	ttlResult := getPipeline.TTL(ctx, r.Key)

	if _, err := getPipeline.Exec(ctx); err != nil && !errors.Is(err, redis.Nil) {
		return nil, errors.Wrapf(err, "failed to execute pipeline with get and ttl to key %v", r.Key)
	}

	var ttlDuration time.Duration

	// we want to make sure there is always an expiration set on the key, so on every
	// increment we check again to make sure it has a TTl and if it doesn't we add one.
	// a duration of -1 means that the key has no expiration so we need to make sure there
	// is one set, this should, most of the time, happen when we increment for the
	// first time but there could be cases where we fail at the previous commands so we should
	// check for the TTL on every request.
	// a duration of -2 means that the key does not exist, given we're already here we should set an expiration
	// to it anyway as it means this is a new key that will be incremented below.
	if d, err := ttlResult.Result(); err != nil || d == keyWithoutExpire || d == keyThatDoesNotExist {
		ttlDuration = r.Duration
		if err := c.client.Expire(ctx, r.Key, r.Duration).Err(); err != nil {
			return nil, errors.Wrapf(err, "failed to set an expiration to key %v", r.Key)
		}
	} else {
		ttlDuration = d
	}

	expiresAt := c.now().Add(ttlDuration)

	if total, err := getResult.Uint64(); err != nil && errors.Is(err, redis.Nil) {

	} else if total >= r.Limit {
		return &Result{
			State:         Deny,
			TotalRequests: total,
			ExpiresAt:     expiresAt,
		}, nil
	}

	incrResult := c.client.Incr(ctx, r.Key)

	totalRequests, err := incrResult.Uint64()
	if err != nil {
		return nil, errors.Wrapf(err, "failed to increment key %v", r.Key)
	}

	if totalRequests > r.Limit {
		return &Result{
			State:         Deny,
			TotalRequests: totalRequests,
			ExpiresAt:     expiresAt,
		}, nil
	}

	return &Result{
		State:         Allow,
		TotalRequests: totalRequests,
		ExpiresAt:     expiresAt,
	}, nil
}
```

Now we read before we increment, making sure we only increment if this is a good request that will be allowed. Otherwise just bail and deny the request before trying anything.

Now we'll look at the updated sorted set implementation:

```go
package redis_rate_limiter

import (
	"context"
	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
	"github.com/pkg/errors"
	"strconv"
	"time"
)

var (
	_ Strategy = &sortedSetCounter{}
)

const (
	sortedSetMax = "+inf"
	sortedSetMin = "-inf"
)

func NewSortedSetCounterStrategy(client *redis.Client, now func() time.Time) Strategy {
	return &sortedSetCounter{
		client: client,
		now:    now,
	}
}

type sortedSetCounter struct {
	client *redis.Client
	now    func() time.Time
}

// Run this implementation uses a sorted set that holds an UUID for every request with a score that is the
// time the request has happened. This allows us to delete events from *before* the current window, if the window
// is 5 minutes, we want to remove all events from before 5 minutes ago, this way we make sure we roll old
// requests off the counters creating a rolling window for the rate limiter. So, if your window is 100 requests
// in 5 minutes and you spread the load evenly across the minutes, once you hit 6 minutes the requests you made
// on the first minute have now expired but the other 4 minutes of requests are still valid.
// A rolling window counter is usually never 0 if traffic is consistent so it is very effective at preventing
// bursts of traffic as the counter won't ever expire.
func (s *sortedSetCounter) Run(ctx context.Context, r *Request) (*Result, error) {
	now := s.now()
	expiresAt := now.Add(r.Duration)
	minimum := now.Add(-r.Duration)

	// first count how many requests over the period we're tracking on this rolling window so check wether
	// we're already over the limit or not. this prevents new requests from being added if a client is already
	// rate limited, not allowing it to add an infinite amount of requests to the system overloading redis.
	// if the client continues to send requests it also means that the memory for this specific key will not
	// be reclaimed (as we're not writing data here) so make sure there is an eviction policy that will
	// clear up the memory if the redis starts to get close to its memory limit.
	result, err := s.client.ZCount(ctx, r.Key, strconv.FormatInt(minimum.UnixMilli(), 10), sortedSetMax).Uint64()
	if err == nil && result >= r.Limit {
		return &Result{
			State:         Deny,
			TotalRequests: result,
			ExpiresAt:     expiresAt,
		}, nil
	}

	// every request needs an UUID
	item := uuid.New()

	p := s.client.Pipeline()

	// we then remove all requests that have already expired on this set
	removeByScore := p.ZRemRangeByScore(ctx, r.Key, "0", strconv.FormatInt(minimum.UnixMilli(), 10))

	// we add the current request
	add := p.ZAdd(ctx, r.Key, &redis.Z{
		Score:  float64(now.UnixMilli()),
		Member: item.String(),
	})

	// count how many non-expired requests we have on the sorted set
	count := p.ZCount(ctx, r.Key, sortedSetMin, sortedSetMax)

	if _, err := p.Exec(ctx); err != nil {
		return nil, errors.Wrapf(err, "failed to execute sorted set pipeline for key: %v", r.Key)
	}

	if err := removeByScore.Err(); err != nil {
		return nil, errors.Wrapf(err, "failed to remove items from key %v", r.Key)
	}

	if err := add.Err(); err != nil {
		return nil, errors.Wrapf(err, "failed to add item to key %v", r.Key)
	}

	totalRequests, err := count.Result()
	if err != nil {
		return nil, errors.Wrapf(err, "failed to count items for key %v", r.Key)
	}

	requests := uint64(totalRequests)

	if requests > r.Limit {
		return &Result{
			State:         Deny,
			TotalRequests: requests,
			ExpiresAt:     expiresAt,
		}, nil
	}

	return &Result{
		State:         Allow,
		TotalRequests: requests,
		ExpiresAt:     expiresAt,
	}, nil
}
```

Now before we add a request to the redis server we check whether there have been too many requests for the period already and if there were we just deny the request before adding a new one to Redis.

## Integrating it as an HTTP middleware

Now that we have implemented two separate counters, how do we make use of them?

One of the ways of doing it is by creating a middleware handler that wraps an existing HTTP handler and adds the rate limiting capability to it so we can compose the handlers with rate limiting when it's needed or just leave them without it if we'd like to, here's what it looks like:

```go
package redis_rate_limiter

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var (
	_            http.Handler = &httpRateLimiterHandler{}
	_            Extractor    = &httpHeaderExtractor{}
	stateStrings              = map[State]string{
		Allow: "Allow",
		Deny:  "Deny",
	}
)

const (
	rateLimitingTotalRequests = "Rate-Limiting-Total-Requests"
	rateLimitingState         = "Rate-Limiting-State"
	rateLimitingExpiresAt     = "Rate-Limiting-Expires-At"
)

// Extractor represents the way we will extract a key from an HTTP request, this could be
// a value from a header, request path, method used, user authentication information, any information that
// is available at the HTTP request that wouldn't cause side effects if it was collected (this object shouldn't
// read the body of the request).
type Extractor interface {
	Extract(r *http.Request) (string, error)
}

type httpHeaderExtractor struct {
	headers []string
}

// Extract extracts a collection of http headers and joins them to build the key that will be used for
// rate limiting. You should use headers that are guaranteed to be unique for a client.
func (h *httpHeaderExtractor) Extract(r *http.Request) (string, error) {
	values := make([]string, 0, len(h.headers))

	for _, key := range h.headers {
		// if we can't find a value for the headers, give up and return an error.
		if value := strings.TrimSpace(r.Header.Get(key)); value == "" {
			return "", fmt.Errorf("the header %v must have a value set", key)
		} else {
			values = append(values, value)
		}
	}

	return strings.Join(values, "-"), nil
}

// NewHTTPHeadersExtractor creates a new HTTP header extractor
func NewHTTPHeadersExtractor(headers ...string) Extractor {
	return &httpHeaderExtractor{headers: headers}
}

// RateLimiterConfig holds the basic config we need to create a middleware http.Handler object that
// performs rate limiting before offloading the request to an actual handler.
type RateLimiterConfig struct {
	Extractor   Extractor
	Strategy    Strategy
	Expiration  time.Duration
	MaxRequests uint64
}

// NewHTTPRateLimiterHandler wraps an existing http.Handler object performing rate limiting before
// sending the request to the wrapped handler. If any errors happen while trying to rate limit a request
// or if the request is denied, the rate limiting handler will send a response to the client and will not
// call the wrapped handler.
func NewHTTPRateLimiterHandler(originalHandler http.Handler, config *RateLimiterConfig) http.Handler {
	return &httpRateLimiterHandler{
		handler: originalHandler,
		config:  config,
	}
}

type httpRateLimiterHandler struct {
	handler http.Handler
	config  *RateLimiterConfig
}

func (h *httpRateLimiterHandler) writeRespone(writer http.ResponseWriter, status int, msg string, args ...interface{}) {
	writer.Header().Set("Content-Type", "text/plain")
	writer.WriteHeader(status)
	if _, err := writer.Write([]byte(fmt.Sprintf(msg, args...))); err != nil {
		fmt.Printf("failed to write body to HTTP request: %v", err)
	}
}

// ServeHTTP performs rate limiting with the configuration it was provided and if there were not errors
// and the request was allowed it is sent to the wrapped handler. It also adds rate limiting headers that will be
// sent to the client to make it aware of what state it is in terms of rate limiting.
func (h *httpRateLimiterHandler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	key, err := h.config.Extractor.Extract(request)
	if err != nil {
		h.writeRespone(writer, http.StatusBadRequest, "failed to collect rate limiting key from request: %v", err)
		return
	}

	result, err := h.config.Strategy.Run(request.Context(), &Request{
		Key:      key,
		Limit:    h.config.MaxRequests,
		Duration: h.config.Expiration,
	})

	if err != nil {
		h.writeRespone(writer, http.StatusInternalServerError, "failed to run rate limiting for request: %v", err)
		return
	}

	// set the rate limiting headers both on allow or deny results so the client knows what is going on
	writer.Header().Set(rateLimitingTotalRequests, strconv.FormatUint(result.TotalRequests, 10))
	writer.Header().Set(rateLimitingState, stateStrings[result.State])
	writer.Header().Set(rateLimitingExpiresAt, result.ExpiresAt.Format(time.RFC3339))

	// when the state is Deny, just return a 429 response to the client and stop the request handling flow
	if result.State == Deny {
		h.writeRespone(writer, http.StatusTooManyRequests, "you have sent too many requests to this service, slow down please")
		return
	}

	// if the request was not denied we assume it was allowed and call the wrapped handler.
	// by leaving this to the end we make sure the wrapped handler is only called once and doesn't have to worry
	// about any rate limiting at all (it doesn't even have to know there was rate limiting happening for this request)
	// as we have already set the headers, so when the handler flushes the response the headers above will be sent.
	h.handler.ServeHTTP(writer, request)
}
```

So what do we have here? We start with the `Extractor` interface that returns a string to be used as the key to a rate limiting check. You could have multiple implementations of this interface, checking HTTP headers or any other fields available on the HTTP request to identify the client, the best way to use this is to have a user/account ID that can be pulled from cookies or headers as IPs change with some frequency, so implement a solution that makes sense for your application.

Then we have the `RateLimiterConfig` struct that wraps all fields needed to perform rate limiting on requests, an `Extractor`, a `Strategy` (our counters), how many requests the client can make and for how long. With all this and an `http.Handler` to wrap we have a fully functional HTTP rate limiter middleware and you could build the same kind of middleware for any other request/response protocol using this same pattern, just changing how this handler is built.

## What should I worry about?

First, as we mentioned before, bursty traffic. Clients that use up their whole limit too fast are still going to be an issue for your systems and while the rolling window limiter diminishes this a little bit it should not be the only thing you're doing to prevent thundering herds of traffic. Another possible solution is to use smaller durations, so instead of giving clients 10_000 requests every hour, give them 160 requests every minute, this way the worst they could do is 160 requests in a short period of time instead of 10_000.

On the same note, do not set limits for very long periods of time, like 100 requests every day, as that makes using the API very frustrating, you make 100 requests and you now have to wait a whole day for the limit to expire again, use smaller periods so people can spread out the load more evenly.

Dynamic deny lists that completely block traffic from specific clients are also a must have on a system like this. You could make this a configuration you'd use on a proxy that sits before the app that performs rate limiting (like a Nginx/Apache server)or at a CDN you're using (like Cloudflare) so you can quickly blackhole all traffic from known abusers.

The implementation we have build here is a *fail closed* solution, which means any error (talking to redis, running extractors)causes the request to be denied. This is mostly because a paranoid implementation is generally safer but might not be the best solution for your service, you might want to have a *best effort* solution that *fails open*, once it finds a failure somewhere during rate limiting it lets the request happen.

While this might be more user friendly it also adds to the risk that abuses could overload the rate limiter and then overload the systems behind it because they now have no protection with the rate limiter down. So before moving completely to a *fail open* solution make sure you have other mitigation measures if the rate limiter fails and there is monitoring on all pieces of the stack, both the app and the Redis servers, so you're notified quickly if any of them start failing and letting on traffic. You might even add an extra HTTP header to downstream clients to let them know that rate limiting failed but the request was still sent so they can make a decision if they want to accept that request or not.

Again, your main goal with rate limiting should be protecting your systems so that you're providing the best service possible for most users and preventing that a small number of misbehaving clients wreak havoc on your applications preventing good users from using them.
