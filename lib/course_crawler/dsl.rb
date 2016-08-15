# a set of useful helper when writing course crawler
module CourseCrawler
  module DSL
    attr_reader :current_url, :html

    def setup
      @cookies = nil
    end

    def visit(url)
      handle_response(RestClient.get(url))
      @current_url = url
    end

    def submit(submit_name = nil, form_data = {})
      submit_selector = "input[type=\"submit\"][value=\"#{submit_name}\"]"

      post_hash = case submit_name
                  when nil
                    get_view_state.merge(form_data)
                  else
                    Hash[@doc.css(submit_selector).map { |node| [node[:name], node[:value]] }].merge(get_view_state).merge(form_data)
                  end

      post_path = @doc.css(submit_selector).xpath('ancestor::form[1]//@action')[0].value

      uri = URI.parse(@current_url)

      post_path = case post_path[0]
                  when '/'
                    "#{uri.scheme}://#{uri.host}/"
                  else
                    URI.join("#{File.dirname(uri.to_s)}/", post_path).to_s
                  end

      post(post_path, post_hash)
    end

    def post(url, opt = {})
      handle_response(RestClient.post(url, opt.merge(cookies: @cookies)))
      @current_url = url
    end

    def get_view_state
      Hash[
        @doc.css('input[type="hidden"]').map { |input| [input[:name], input[:value]] }
      ]
    end

    private

    def handle_response(response)
      @doc  = Nokogiri::HTML(response.force_encoding(response.encoding))
      @html = response

      @cookies ||= response.cookies
    end
  end
end
