# this script is used to invite users
# Usage
# > ruby invite.rb -f Riley -l Shenk -e rjshenk@gmail.com 
#   -k xoxp-2895144450-5173338419-9130635876-22e3e2 -v
# Or 
# > ruby invite.rb --first_name Riley --last_name Shenk --email rjshenk@gmail.com 
#   --api_key xoxp-2895144450-5173338419-9130635876-22e3e2 --verbose
# Command line arguments can be given in any order
# 
#

require 'optparse'
require "uri"
require 'pp'
require 'json'
require "net/http"

# hash to hold options given in the command line
options = {:email => nil, :first_name => nil, :last_name => nil, :verbose => false, :api_key => nil}  

parser = OptionParser.new do|opts|
    opts.banner = "Usage: invite.rb [options]"	

    opts.on('-f', '--first_name [first_name]', 'first_name of new user (optional)') do |first_name|
        options[:first_name] = first_name
    end

    opts.on('-l','--last_name [last_name]', 'last_name of new user (optional)') do |last_name|
        options[:last_name] = last_name
    end

    opts.on('-e', '--email email', 'email address that you are inviting to slack') do |email|
        options[:email] = email;
    end

    opts.on('-k', '--api_key key', 'api_key') do |key|
        options[:api_key] = key
    end

    opts.on('-v', '--verbose', 'turn on verbose mode for feedback') do
        options[:verbose] = true
    end

    opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
    end
end
parser.parse!

# To invite a user an email and api_key must be given
if options[:email] == nil || options[:api_key] == nil
	puts "Error: manditory information was missing, user must give email and api_key" 
    puts "Try the -h flag for help on how to use invite.rb"
    puts "quiting now"
	exit 1
end

if options[:verbose]
    puts "arguments recieved from user:"
    pp options
end

# This method is used for error checking
def check_response(response, message, error_handling = :fatal_error, interactive_mode = false)
    if !response["ok"]
        STDERR.puts "Error: \"#{response["error"]}\" - " + message
        if error_handling == :fatal_error 
            exit 1
        end
    end    
end

# actually inviting the user
method = "users.admin.invite?"
slackHost = "https://slack.com/api/"
uri = URI(slackHost + method)
full_name = nil
if options[:first_name] && options[:last_name]
    full_name = options[:first_name] + " " + options[:last_name]
    emailInviteResponse = JSON.parse(Net::HTTP.post_form(uri, 
        "email" => options[:email], "token" => options[:api_key], "first_name" => options[:first_name], 
        "last_name" => options[:last_name], "set_active" => true).body)
else 
    puts "No"
    exit 1
    emailInviteResponse = JSON.parse(Net::HTTP.post_form(uri, 
        "email" => options[:email], "token" => options[:api_key], "set_active" => true).body)
end
#check response for error, if error encountered the message given will be printed and it will exit immediately 
check_response(emailInviteResponse, "encountered when trying to invite #{options[:email]}", :fatal_error, options[:verbose])

#print response if verbose mode is turned on
if options[:verbose] 
    print "Successfuly sent invitation to #{options[email]}"
    if full_name
        puts " with name set up as #{full_name}"
    else 
        puts " with no name given"    
    end             
end

