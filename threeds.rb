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
      cus = Stripe::Customer.create(
        :description => "Customer",
        :source => request["source"]
      )

      source = Stripe::Source.create({
        amount: 100,
        currency: 'sgd',
        type: 'three_d_secure',
        three_d_secure: { customer: cus.id },
        redirect: { return_url: DOMAIN + '/redirect' },
      })

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

    get '/failure' do
      erb :failure, :locals => { :pk => ENV['STRIPE_PUBLISHABLE_KEY'] }
    end

    post '/webhooks' do
      # Retrieve the request's body and parse it as JSON
      event_json = JSON.parse(request.body.read)
      event_object = event_json["data"]["object"]

      # Create a charge if source chargeable
      if event_json["type"] == "source.chargeable" && 
         event_object["type"] == "three_d_secure" &&
         event_object["three_d_secure"]["authenticated"]
        
        ch1 = Stripe::Charge.create(
          :amount => event_object["amount"],
          :currency => event_object["currency"],
          :source => event_object["id"],
          :customer => event_object["three_d_secure"]["customer"],
          :description => "Test 3DS Charge"
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