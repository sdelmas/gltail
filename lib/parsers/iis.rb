# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles Internet Information Server (IIS) logs
class IISParser < Parser
  def parse( line )
    _, date, time,serverip, url, referrer, port, size, host, useragent, status = /^([\d-]+) ([\d:]+) ([\d.]+) (.+? .+?) (\S+) (.+?) (\S+) ([\d.]+) (.+?) (\d+) (.*)$/.match(line).to_a

    if host
      _, referrer_host, referrer_url = /^http[s]?:\/\/([^\/]+)(\/.*)/.match(referrer).to_a if referrer
      method, url, http_version = url.split(" ")
      url, parameters = url.split('?')

      server.add_activity(:block => 'sites', :name => server.name, :size => size.to_i/1000000.0) # Size of activity based on size of request
      server.add_activity(:block => 'urls', :name => url)
      server.add_activity(:block => 'users', :name => host, :size => size.to_i/1000000.0)
      server.add_activity(:block => 'referrers', :name => referrer) unless (referrer_host.nil? || referrer_host.include?(server.name) || referrer_host.include?(server.host) || referrer == '-')
      server.add_activity(:block => 'user agents', :name => useragent, :type => 3)

      if( url.include?('.gif') || url.include?('.jpg') || url.include?('.png') || url.include?('.ico'))
        type = 'image'
      elsif url.include?('.css')
        type = 'css'
      elsif url.include?('.js')
        type = 'javascript'
      elsif url.include?('.swf')
        type = 'flash'
      elsif( url.include?('.avi') || url.include?('.ogm') || url.include?('.flv') || url.include?('.mpg') )
        type = 'movie'
      elsif( url.include?('.mp3') || url.include?('.wav') || url.include?('.fla') || url.include?('.aac') || url.include?('.ogg'))
        type = 'music'
      else
        type = 'page'
      end
      server.add_activity(:block => 'content', :name => type)
      server.add_activity(:block => 'status', :name => status, :type => 3) # don't show a blob

      # Events to pop up
      server.add_event(:block => 'info', :name => "Logins", :message => "Login...", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('login')
      server.add_event(:block => 'info', :name => "Sales", :message => "$", :update_stats => true, :color => [1.5, 0.0, 0.0, 1.0]) if method == "POST" && url.include?('/checkout')
      server.add_event(:block => 'info', :name => "Signups", :message => "New User...", :update_stats => true, :color => [1.0, 1.0, 1.0, 1.0]) if( method == "POST" && (url.include?('/signup') || url.include?('/users/create')))
    end
  end
end
