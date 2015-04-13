require "rubygems"
require "uri"
require "rest_client"
require "io/console"

module CRTC

    class Client

        def initialize(server_url,ssl=true, cookie_dir='./tmp')
          @server_url = server_url
          @cookie_dir = cookie_dir
          @resource = (ssl)?"https://#{server_url}/REST/1.0":"#{server_url}/REST/1.0"
          @headers = {
            'User-Agent' => "Mozilla/5.0 CRTC - Crappy Request Tracker Client",
            'Content-Type' => 'application/x-www-form-urlencoded'
          }
        end
        
        def has_cookie?
            @cookie
        end

        def login_with_cookie user
          @cookie_path = "#{@cookie_dir}/#{user}.txt"
          Dir.mkdir("./tmp") if !Dir.exists?(@cookie_dir)
          if File.exists?(@cookie_path) 
            cookie_file = File.open(@cookie_path, "r")
            @headers['Cookie'] = cookie_file.read().chomp
            cookie_file.close
            @cookie = true
            @logged_in = true
            @server = RestClient::Resource.new @resource, :headers => @headers
          else
              @logged_in = false
              @cookie = false
              false
          end
        end
        
        def login(user, pass)
          cred = { :user => user, :pass => pass }
          resp = RestClient.post @resource, cred
          if resp =~ /200/
            @headers['Cookie'] = resp.headers[:set_cookie].to_s.split(';')[0][2..-1]
            Dir.mkdir("./tmp") if !Dir.exists?(@cookie_dir)
            @cookie_path = "#{@cookie_dir}/#{user}.txt"
            cookie_file = File.open(@cookie_path, "w+")
            cookie_file << @headers['Cookie']
            @user = user
            @server = RestClient::Resource.new @resource, :headers => @headers
            @logged_in = true
            return :logged_in 
          elsif resp =~ /401/
            @logged_in = false
            return :credentials_required 
          end
        end 

        def interactive_login(user=false)
          puts "loading cookie"
          login_with_cookie user if user
          if !has_cookie?
              puts "No cookie found, asking for credentials"
              loop do
                  puts "Username:"
                  user = gets.chomp
                  puts "Password:"
                  STDIN.echo = false 
                  pass = gets.chomp
                  STDIN.echo = true
                  puts "Logging in......."
                  puts login(user, pass)
                  break if @logged_in
                  puts "Authentication failed, try again or ^C"
              end
                  puts "Login successful!"
          end
          puts "We have a cookie, nothing to do"
        end
    end
end
