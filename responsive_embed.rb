require 'cgi'
require 'uri'

EMBED = %(<style>.embed-container { position: relative; padding-bottom: 56.25%%; height: 0; overflow: hidden; max-width: 100%%; height: auto; } .embed-container iframe, .embed-container object, .embed-container embed { position: absolute; top: 0; left: 0; width: 100%%; height: 100%%; }</style><div class='embed-container'>%{video}</div>)

VIMEO = %(<iframe src="%{scheme}://player.vimeo.com/video/%{video_id}" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>)

YOUTUBE = %(<iframe src="%{scheme}://www.youtube.com/embed/%{video_id}/" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowfullscreen></iframe>)

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
      context = {
        scheme: url.scheme
      }
      unless ENV["RESPONSIVE_EMBED_SCHEME"].nil?
        context['scheme'] = ENV["RESPONSIVE_EMBED_SCHEME"]
      end

      if url.host.include?('youtube.com')
        # get the YouTube iframe
        context[:video_id] = params['v']
        video = YOUTUBE % context
      elsif url.host.include?('vimeo.com')
        # get the Vimeo iframe
        context[:video_id] = url.path[1..-1]
        video = VIMEO % context
      end
      unless video.nil?
        embed = EMBED % {video: video}
      end
    end

    def convert(content)
      re = %r{(\n    )?(\[.*\])\((http.*)\)}
      m = content.scan re
      m.each do |match|
        next unless match[0].nil?
        href = match[2]
        if href and interesting_url(href)
          url = URI(href)
          params = CGI.parse(url.query)
          if params.key?('jekyll_embed')
            embed = get_embed_markup(url, params)
            # if we have some embed markup replace the Markdown link with it
            if embed
              content = content.gsub("#{match[1]}(#{match[2]})", embed)
            end
          end
        end
      end
      content
    end
  end
end
