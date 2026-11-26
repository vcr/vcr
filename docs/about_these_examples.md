The cucumber features provided here demonstrate all of the major features of
VCR.  These features are executable documentation for VCR.

Many of the examples use one (or both) of these helper functions
provided by `spec/support/cucumber_helpers.rb`:

* `start_sinatra_app`: starts a sinatra application on the given port.
  The server automatically shuts down when the ruby script ends.  Many
  examples re-run the script without the sinatra server to demonstrate
  the replaying of a recorded HTTP response.
* `include_http_adapter_for`: includes a module that implements a common
  HTTP interface for the given HTTP library.  The `response_body_for`
  method will make an HTTP request using the given library.  This
  allows scenarios to be run against each different supported HTTP
  library.

If you have ideas to clarify or improve any of these cucumber features,
please submit an [issue](https://github.com/vcr/vcr/issues) or pull request.
