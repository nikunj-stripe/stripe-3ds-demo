require "sinatra"
require "sinatra/json"
require "stripe"

module ThreeDS
  class App < Sinatra::Application

    configure :development do
      require 'dotenv'
      Dotenv.load
    end

    configure do
      Stripe.api_key = ENV['STRIPE_SECRET_KEY']
      DOMAIN = ENV['DOMAIN']
    end

    get '/' do
      erb :index, :locals => { :pk => ENV['STRIPE_PUBLISHABLE_KEY'] }
    end

    post '/charge' do
      puts "[Charge] Requst Source:"
      puts request["source"]
      source = Stripe::Source.create({
        amount: 200,
        currency: 'sgd',
        type: 'three_d_secure',
        three_d_secure: { card: request["source"] },
        redirect: { return_url: DOMAIN + '/redirect' },
      })
      puts "[Charge] Source Object Returned:"
      puts source.status
      if source.status == "failed"
        redirect to('/')
      else
        redirect source.redirect.url
      end
    end

    get '/redirect' do
      erb :redirect, :locals => { 
        :pk => ENV['STRIPE_PUBLISHABLE_KEY'],
        :client_secret => request['client_secret'],
        :source => request['source']
      }
    end

    get '/success' do
      erb :success, :locals => { :pk => ENV['STRIPE_PUBLISHABLE_KEY'] }
    end

    post '/webhooks' do
      # Retrieve the request's body and parse it as JSON
      event_json = JSON.parse(request.body.read)

      # Create a charge if source chargeable
      if event_json["type"] == "source.chargeable" && 
         event_json["data"]["object"]["status"] == "chargeable"
        ch1 = Stripe::Charge.create(
          :amount => event_json["data"]["object"]["amount"],
          :currency => event_json["data"]["object"]["currency"],
          :source => event_json["data"]["object"]["id"],
          :description => "Test Charge"
        )
      end

      status 200
    end

    # Other
    get '/charge' do
      redirect to('/')
    end

    not_found do
      erb :"404", :layout => false
    end

  end
end