require 'cgi'
require 'uri'

module Jekyll

  class ResponsiveEmbedConverter < Converter
    safe true
    priority :highest
    @@domains = %w(youtube.com vimeo.com)

    def matches(ext)
      ext =~ /^\.md$/i
    end

    def output_ext(ext)
      ".html"
    end

    def interesting_domain(href)
      @@domains.any? { |s| href.include?(s) }
    end

    def interesting_url(href)
      interesting_domain(href) && href.include?('jekyll_embed')
    end

    def get_embed_markup(url, params)
      # the URL has a jekyll_embed GET paramter
      if url.host.include?('youtube.com')
        # get the YouTube iframe
        layout = Liquid::Template.parse(
          File.new(File.join("_includes", "_youtube.html")).read)
        embed = layout.render({'video_id' => params['v']})
      elsif url.host.include?('vimeo.com')
        # get the Vimeo iframe
        layout = Liquid::Template.parse(
          File.new(File.join("_includes", "_vimeo.html")).read)
        embed = layout.render({
          'video_id' => url.path[1..-1],
          'scheme' => url.scheme
        })
      end
    end

    def convert(content)
      re = %r{(\[.*\])\((http.*)\)}
      m = content.scan re
      m.each do |match|
        href = match[1]
        if href and interesting_url(href)
          url = URI(href)
          params = CGI.parse(url.query)
          if params.key?('jekyll_embed')
            embed = get_embed_markup(url, params)
            # if we have some embed markup replace the Markdown link with it
            if embed
              content = content.gsub("#{match[0]}(#{match[1]})", embed)
            end
          end
        end
      end
      content
    end
  end
end
