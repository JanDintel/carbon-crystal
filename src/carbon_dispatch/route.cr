module CarbonDispatch
  class Route
    macro create(controller, action, pattern)
      CarbonDispatch::Route.new "{{controller.id.capitalize}}Controller",
                                {{action}},
                                {{pattern}},
                                ->(request : CarbonDispatch::Request, response : CarbonDispatch::Response) {
        {{controller.id.capitalize}}Controller.action({{action}}, request, response)
      }
    end

    getter controller
    getter action
    getter pattern

    def initialize(@controller, @action, path, @block)
      @params = [] of String
      lparen = path.split(/(\()/)
      rparen = lparen.flat_map { |word| word.split(/(\))/) }
      params = rparen.flat_map { |word| word.split(/(:\w+)/) }
      slugged = params.flat_map { |word| word.split(/(\*\w+)/) }
      pattern = slugged.map do |word|
                  word.gsub(/\(/) { "(?:" }
                      .gsub(/\)/) { "){0,1}" }
                      .gsub(/:(\w+)/) { @params << $1; "(?<#{$1}>[^/]+)" }
                      .gsub(/\*(\w+)/) { @params << $1; "(?<#{$1}>.+)" }
                end.join

      @pattern = Regex.new("^#{pattern}$")
    end

    def match(path)
      path = normalize_path(path)

      match = path.to_s.match(@pattern)

      if match
        @params.inject({} of String => String?) { |hash, param| hash[param] = match[param]?; hash }
      else
        false
      end
    end

    def normalize_path(path)
      path = "/#{path}"
      path = path.squeeze("/")
      path = path.sub(%r{/+\Z}, "")
      path = path.gsub(/(%[a-f0-9]{2})/) { $1.upcase }
      path = "/" if path == ""
      path
    end

    def call(request : CarbonDispatch::Request, response : CarbonDispatch::Response)
      @block.call(request, response)
    end

    def ==(other)
      @controller == other.controller && @action == other.action
    end
  end
end
