require 'dotenv'
require 'sinatra'
require 'messagebird'

set :root, File.dirname(__FILE__)

#  Load configuration from .env file
Dotenv.load if Sinatra::Base.development?

# Load and initialize MesageBird SDK
client = MessageBird::Client.new(ENV['MESSAGEBIRD_API_KEY'])

# Render landing page
get '/' do
  erb :landing, locals: { error: nil, name: nil, number: nil }
end

def blank?(var)
  var.nil? || var.empty?
end

# Handle request
post '/callme' do
  # Check if user has provided input for all form fields
  if blank?(params[:name]) || blank?(params[:number])
    return erb :landing, locals: {
      error: 'Please fill all required fields!',
      name: params[:name],
      number: params[:number]
    }
  end

  # Choose one of the sales agent numbers randomly
  # a) Convert comma-separated values to array
  numbers = ENV['SALES_AGENT_NUMBERS'].split(',')
  # b) Random number between 0 and (number count - 1)
  random_index = rand(0...numbers.length)
  # c) Pick number
  recipient = numbers[random_index]

  begin
    response = client.message_create(ENV['MESSAGEBIRD_ORIGINATOR'], [ recipient ], "You have a new lead: #{params[:name]}. Call them at #{params[:number]}")
    # Message was sent successfully
    puts response
    return erb :sent
  rescue MessageBird::ErrorException => ex # Message could not be sent
    errors = ex.errors.each_with_object([]) do |error, memo|
      memo << "Error code #{error.code}: #{error.description}"
    end.join("\n")

    puts errors

    return erb :landing, locals: {
      error: errors,
      name: params[:name],
      number: params[:number]
    }
  end
end
