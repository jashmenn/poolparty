pool :application do
  instances 2..10
  
  cloud :pp1 do
    has_directory "/var/www"
    has_file      "/etc/motd", :content => "Hi hi"

    enable :haproxy # loads apache
    
    has_file :name => "/var/www/index.html" do
      content "<h1>Welcome to your new poolparty instance <%= @node[:poolparty][:name] %>"
      mode 0644
    end
  end
 
end