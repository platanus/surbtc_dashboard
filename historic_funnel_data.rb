require 'rubygems'
require 'active_support/all'
require 'net/http'
require 'uri'
require 'rest-client'
require 'google/api_client'
require 'date'
Dir[File.dirname(__FILE__) + "/lib/**/*.rb"].each {|file| require file }

# Update these to match your own apps credentials
service_account_email = 'dashboard01@surbtc-ga.iam.gserviceaccount.com' # Email of service account
key_file = './dashboard01.p12' # File containing your private key
key_secret = 'notasecret' # Password to unlock private key
profileID = '112579615' # Analytics profile ID.

# Get the Google API client
client = Google::APIClient.new(:application_name => 'Dashboard01', 
  :application_version => '0.01')

# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/analytics.readonly',
  :issuer => service_account_email,
  :signing_key => key)

        client.authorization.fetch_access_token!
        analytics = client.discovered_api('analytics','v3')
puts ["From", "To", "Adquiridos", "Activados", "Retenidos", "Churn Rate"].join("\t")
7.times do |i|
        from = (Time.now - (1+i)*30.days)
        to = from + 30.days
        startDate = from.strftime("%Y-%m-%d") 
        endDate = to.strftime("%Y-%m-%d")  # now

        visitCount = client.execute(:api_method => analytics.data.ga.get, :parameters => { 
          'ids' => "ga:" + profileID, 
          'start-date' => startDate,
          'end-date' => endDate,
          # 'dimensions' => "ga:month",
          #'metrics' => "ga:visitors",
          'metrics' => "ga:newUsers",
          # 'sort' => "ga:month" 
        })

        visitors = visitCount.data.rows[0][0].to_i

        exchange = Exchange::Api.new

        now = exchange.get_users_stats from, to

	highschoolers = now.highschoolers.to_i
        undergrads = now.undergrads.to_i
        comebackers = now.comebackers.to_i
        oldies = now.oldies.to_i
        churn_rate = now.churn_rate.to_f

	progress_items = [{ name: "Adquiridos", progress: (100*highschoolers.to_f/visitors).round(4) }, #  registros/visitantes
		          { name: "Activados", progress: (100*undergrads.to_f/highschoolers).round(4) }, #  primera compra/registros
		          { name: "Retenidos", progress: (100*comebackers.to_f/oldies).round(4) }, #  comebackers/oldies
		          { name: "Churn Rate", progress: (100*churn_rate).round(4) }  
	]
        print "#{from.strftime("%m-%d-%Y")}\t#{to.strftime("%m-%d-%Y")}\t"
        print [(100*highschoolers.to_f/visitors).round(4), (100*undergrads.to_f/highschoolers).round(4), (100*comebackers.to_f/oldies).round(4), (100*churn_rate).round(4)].collect(&:to_s).join("\t") + "\n"
        sleep 5
end
