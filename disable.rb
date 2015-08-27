# this script is used to disable users who have been disabled
# Usage
# > ruby disable.rb -f Riley -l Shenk -e some_email@gmail.com 
#   -k xoxp-2895144450-5173338419-9130635876-22e3e2 -v
# Or 
# > ruby disable.rb --first_name Riley --last_name Shenk --email some_email@gmail.com 
#   --api_key xoxp-2895144450-5173338419-9130635876-22e3e2 --verbose
# Command line arguments can be given in any order


require 'optparse'
require "uri"
require 'pp'
require 'json'
require "net/http"
require './error_handling'

# hash to hold targetUser given in the command line
targetUser = {:email => nil, :username => nil, :verbose => false, :api_key => nil}  

parser = OptionParser.new do|opts|
    opts.banner = "Usage: disable.rb [targetUser]"   

    opts.on('-e', '--email email', 'email address attached to 
                                    the account you are disabling') do |email|
        targetUser[:email] = email;
    end

    opts.on('-u', '--username username', 'username you are disabling') do |username|
        targetUser[:username] = username;
    end

    opts.on('-k', '--api_key key', 'api_key') do |key|
        targetUser[:api_key] = key
    end

    opts.on('-v', '--verbose', 'turn on verbose mode for feedback') do
        targetUser[:verbose] = true
    end

    opts.on('-h', '--help', 'Displays Help') do
        puts opts
        exit
    end
end
parser.parse!

# ---------------------------------- Methods ----------------------------------
#This method returns a hash with all the slack users in it
def getAllSlackUsers(api_key, remove_deleted_accounts = false)
    #getting all the users in the slack team. 
    slackHost = "https://slack.com/api/"
    method = "users.list?"
    uri = URI(slackHost + method)
    response = JSON.parse(Net::HTTP.post_form(uri, "token" => api_key).body)
    check_response(response, "encountered when trying to get a list 
                              of all slack users", :fatal_error)
    if remove_deleted_accounts
        response["members"].delete_if { |hash| hash["deleted"] }
    end
    response
end

#this method takes in a name and trys to find the userID associated with that name
#test where exit 1 returns you to
def getUserID(targetUser, api_key)
    username = targetUser[:username]
    email = targetUser[:email]
    allUsers = getAllSlackUsers(api_key)
    if allUsers["ok"]                           
        allUsers["members"].each{ |hash|
            if (hash["name"] == username && username != nil) || 
                (hash["profile"]["email"] == email && email != nil)
                return hash["id"] 
            end
        }
    else
        STDERR.puts "Error: #{allUsers["error"]} - encountered when searching 
        for user associated with " + 
        (targetUser[:email] == nil ? targetUser[:username] : targetUser[:email]).to_s
    end
    STDERR.puts "Error: could not find user associated with " + 
        (targetUser[:email] == nil ? targetUser[:username] : targetUser[:email]).to_s  
    exit 1
end

# ---------------------------------- Main ----------------------------------
if targetUser[:verbose]
    puts "arguments recieved from user:"
    pp targetUser
end

# To disable a user an email or username must be given
if (targetUser[:email] == nil && targetUser[:username] == nil) || 
    targetUser[:api_key] == nil
    puts "Error: manditory information was missing, make sure to give an 
          api_key with either an email or a username" 
    puts "Try the -h flag for help on how to use disable.rb"
    puts "quiting now"
    exit 1
end

#Finding the userID associated with the email given
targetUser[:userID] = getUserID(targetUser, targetUser[:api_key])

#Disabling the account       
method = "users.admin.setInactive?"
slackHost = "https://slack.com/api/"
uri = URI(slackHost + method)
disableResponse = JSON.parse(Net::HTTP.post_form(uri, 
    "user" => targetUser[:userID], "token" => targetUser[:api_key], "set_active" => true, "_attempts" => 1).body)
check_response(disableResponse,"encountered when trying to disable account", :fatal_error)
if targetUser[:verbose] 
    print "Success: " 
    puts (targetUser[:username] ? targetUser[:username] : targetUser[:email]) + 
         " was disabled"
end
