In order to properly replay previously recorded requests, VCR must match new
HTTP requests to a previously recorded one. By default, it matches on HTTP
method and URI, since that is usually deterministic and fully identifies the
resource and action for typical RESTful APIs.

You can customize how VCR matches requests using the `:match_requests_on` cassette option.
Specify an array of attributes to match on.  Supported attributes are:

  - `:method` - The HTTP method (i.e. GET, POST, PUT or DELETE) of the request.
  - `:uri` - The full URI of the request.
  - `:host` - The host of the URI. You can use this (alone, or in combination
    with `:path`) as an alternative to `:uri` to cause VCR to match using a regex
    that matches the host.
  - `:path` - The path of the URI. You can use this (alone, or in combination
    with `:host`) as an alternative to `:uri` to cause VCR to match using a regex
    that matches the path.
  - `:query` - The query string values of the URI. The query string ordering does
    not affect matching results (it's order-agnostic).
  - `:body` - The body of the request.
  - `:headers` - The request headers.

You can also register a custom request matcher. This particularly comes
in handy for dealing with APIs that use non-deterministic URIs (i.e. by
including a timestamp as a query parameter or whatever).

When a cassette contains multiple HTTP interactions that match a request
based on the configured `:match_requests_on` setting, the responses are
sequenced: the first matching request will get the first response,
the second matching request will get the second response, etc.

