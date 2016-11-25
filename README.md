<p align="center">
<img src="https://raw.github.com/maestrano/maestrano-ruby/master/maestrano.png" alt="Maestrano Logo">
<br/>
<br/>
</p>

Maestrano Cloud Integration is currently in closed beta. Want to know more? Send us an email to <contact@maestrano.com>.

[![Build Status](https://travis-ci.org/maestrano/maestrano-ruby.svg)](https://travis-ci.org/maestrano/maestrano-ruby)
[![Gem Version](https://badge.fury.io/rb/maestrano.svg)](https://rubygems.org/gems/maestrano)

- - -

1.  [Getting Setup](#getting-setup)
2.  [Getting Started with Rails](#getting-started-with-rails)
3. [Getting Started](#getting-started)
  * [Installation](#installation)
  * [Configuration](#configuration)
  * [Metadata Endpoint](#metadata-endpoint)
4. [Single Sign-On Setup](#single-sign-on-setup)
  * [User Setup](#user-setup)
  * [Group Setup](#group-setup)
  * [Controller Setup](#controller-setup)
  * [Other Controllers](#other-controllers)
5. [Account Webhooks](#account-webhooks)
  * [Groups Controller](#groups-controller-service-cancellation)
  * [Group Users Controller](#group-users-controller-business-member-removal)
6. [API](#api)
  * [Payment API](#payment-api)
    * [Bill](#bill)
    * [Recurring Bill](#recurring-bill)
  * [Membership API](#membership-api)
    * [User](#user)
    * [Group](#group)
7. [Connec!™ Data Sharing](#connec-data-sharing)
  * [Making Requests](#making-requests)
  * [Webhook Notifications](#webhook-notifications)

- - -

## Getting Setup
Before integrating with us you will need an App ID and API Key. Maestrano Cloud Integration being still in closed beta you will need to contact us beforehand to gain production access.

For testing purpose we provide an API Sandbox where you can freely obtain an App ID and API Key. The sandbox is great to test single sign-on and API integration (e.g: billing API).

To get started just go to: http://api-sandbox.maestrano.io

## Getting Started with Rails

If you're looking at integrating Maestrano in your Rails application then you should use the maestrano-rails gem.

More details on the [maestrano-rails project page](https://github.com/maestrano/maestrano-rails).

## Getting Started

### Installation

To install the gem run
```console
gem install maestrano
```

Or add it to your Gemfile
```ruby
gem 'maestrano'
```


### Configuration
Once installed the first step is to create an initializer to configure the behaviour of the Maestrano gem

#### Configuration based of the Developer Platform
The [developer platform](https://dev-platform.maestrano.com) is the easiest way to configure Maestrano. The only actions needed from your part is to create your application and environments on the developer platform and to create a config file. The framework will then contact the developer platform and retrieve the marketplaces configuration for your app environment.

In your initializer add the following configuration:

`config/initializers/maestrano.rb`
```ruby
Maestrano.auto_configure('config/dev_platform.yml')
```

`dev_platform.yml`
```yml
dev_platform:
  host: 'https://dev-platform.maestrano.com'
  api_path: '/api/config/v1/marketplaces'

environment:
  name: 'my-environment'
  api_key: 'your-environment-api-key'
  api_secret: 'your-environment-api-secret'
```

The API keys can be found under your Environment settings on the developer platform.

Note that the configuration can also be set from environment variables:

```bash
export MNO_DEVPL_HOST=<developer platform host>
export MNO_DEVPL_API_PATH=<developer platform path>
export MNO_DEVPL_ENV_NAME=<your environment nid>
export MNO_DEVPL_ENV_KEY=<your environment key>
export MNO_DEVPL_ENV_SECRET=<your environment secret>
```

`config/initializers/maestrano.rb`
```ruby
Maestrano.auto_configure
```

#### Deprecated - Configure environments manually
Environments configuration should be driven from the developer platform configuration. For backward compatibility purpose, environments can still be defined manually.

You can add configuration presets by putting additional configuration blocks in your maestrano.rb initializer. These additional presets can then be specified when doing particular action, such as initializing a Connec!™ client or triggering a SSO handshake. These presets are particularly useful if you are dealing with multiple Maestrano-style marketplaces (multi-enterprise integration).

If this is the first time you integrate with Maestrano, we recommend adopting a multi-tenant approach. All code samples in this documentation provide examples on how to handle multi-tenancy by scoping method calls to a specific configuration preset.

More information about multi-tenant integration can be found on [Our Multi-Tenant Integration Guide](https://maestrano.atlassian.net/wiki/display/CONNECAPIV2/Multi-Tenant+Integration)

The initializer should look like this:
```ruby
# Use this block to configure the behaviour of Maestrano
# in your app
Maestrano.configure do |config|
  
  # ==> Environment configuration
  # The environment to connect to.
  # If set to 'production' then all Single Sign-On (SSO) and API requests
  # will be made to maestrano.com
  # If set to 'test' then requests will be made to api-sandbox.maestrano.io
  # The api-sandbox allows you to easily test integration scenarios.
  # More details on http://api-sandbox.maestrano.io
  #
  config.environment = 'test' # or 'production'
  
  # ==> Application host
  # This is your application host (e.g: my-app.com) which is ultimately
  # used to redirect users to the right SAML url during SSO handshake.
  #
  config.app.host = (config.environment == 'production' ? 'https://my-app.com' : 'http://localhost:3000')
  
  # ==> App ID & API key
  # Your application App ID and API key which you can retrieve on http://maestrano.com
  # via your cloud partner dashboard.
  # For testing you can retrieve/generate an api.id and api.key from the API Sandbox directly 
  # on http://api-sandbox.maestrano.io
  #
  config.api.id = (config.environment == 'production' ? 'prod_app_id' : 'sandbox_app_id')
  config.api.key = (config.environment == 'production' ? 'prod_api_key' : 'sandbox_api_key')
  
  # ==> Single Sign-On activation
  # Enable/Disable single sign-on. When troubleshooting authentication issues
  # you might want to disable SSO temporarily
  #
  # config.sso.enabled = true
  
  # ==> Single Sign-On Identity Manager
  # By default we consider that the domain managing user identification
  # is the same as your application host (see above config.app.host parameter)
  # If you have a dedicated domain managing user identification and therefore
  # responsible for the single sign-on handshake (e.g: https://idp.my-app.com)
  # then you can specify it below
  #
  # config.sso.idm = (config.environment == 'production' ? 'https://idp.my-app.com' : 'http://localhost:3000')
  
  # ==> SSO Initialization endpoint
  # This is your application path to the SAML endpoint that allows users to
  # initialize SSO authentication. Upon reaching this endpoint users your
  # application will automatically create a SAML request and redirect the user
  # to Maestrano. Maestrano will then authenticate and authorize the user. Upon
  # authorization the user gets redirected to your application consumer endpoint
  # (see below) for initial setup and/or login.
  #
  # config.sso.init_path = '/maestrano/auth/saml/init'
  
  # ==> SSO Consumer endpoint
  # This is your application path to the SAML endpoint that allows users to
  # finalize SSO authentication. During the 'consume' action your application
  # sets users (and associated group) up and/or log them in.
  #
  # config.sso.consume_path = '/maestrano/auth/saml/consume'
  
  # ==> Single Logout activation
  # Enable/Disable single logout. When troubleshooting authentication issues
  # you might want to disable SLO temporarily.
  # If set to false then Maestrano::SSO::Session#valid? - which should be
  # used in a controller before filter to check user session - always return true
  #
  # config.sso.slo_enabled = true

  # ==> x509 SSL Certificate
  # During the SSO handshake, the SSL certificate is validated and must match the IDP provider.
  # For multi-tenant integration, the certificates may change per environment.
  #
  # config.sso.x509_fingerprint = '2f:57:71:e4:40:19:57:37:a6:2c:f0:c5:82:52:2f:2e:41:b7:9d:7e'
  # config.sso.x509_certificate = "-----BEGIN CERTIFICATE-----\nCERTIFICATE CONTENT==\n-----END CERTIFICATE-----"
  
  # ==> SSO User creation mode
  # !IMPORTANT
  # On Maestrano users can take several "instances" of your service. You can consider
  # each "instance" as 1) a billing entity and 2) a collaboration group (this is
  # equivalent to a 'customer account' in a commercial world). When users login to
  # your application via single sign-on they actually login via a specific group which
  # is then supposed to determine which data they have access to inside your application.
  #
  # E.g: John and Jack are part of group 1. They should see the same data when they login to
  # your application (employee info, analytics, sales etc..). John is also part of group 2 
  # but not Jack. Therefore only John should be able to see the data belonging to group 2.
  #
  # In most application this is done via collaboration/sharing/permission groups which is
  # why a group is required to be created when a new user logs in via a new group (and 
  # also for billing purpose - you charge a group, not a user directly). 
  #
  # == mode: 'real'
  # In an ideal world a user should be able to belong to several groups in your application.
  # In this case you would set the 'sso.creation_mode' to 'real' which means that the uid
  # and email we pass to you are the actual user email and maestrano universal id.
  #
  # == mode: 'virtual'
  # Now let's say that due to technical constraints your application cannot authorize a user
  # to belong to several groups. Well next time John logs in via a different group there will
  # be a problem: the user already exists (based on uid or email) and cannot be assigned 
  # to a second group. To fix this you can set the 'sso.creation_mode' to 'virtual'. In this
  # mode users get assigned a truly unique uid and email across groups. So next time John logs
  # in a whole new user account can be created for him without any validation problem. In this
  # mode the email we assign to him looks like "usr-sdf54.cld-45aa2@mail.maestrano.com". But don't
  # worry we take care of forwarding any email you would send to this address
  #
  # config.sso.creation_mode = 'real' # or 'virtual'
  
  # ==> Account Webhooks
  # Single sign on has been setup into your app and Maestrano users are now able
  # to use your service. Great! Wait what happens when a business (group) decides to 
  # stop using your service? Also what happens when a user gets removed from a business?
  # Well the endpoints below are for Maestrano to be able to notify you of such
  # events.
  #
  # Even if the routes look restful we issue only issue DELETE requests for the moment
  # to notify you of any service cancellation (group deletion) or any user being
  # removed from a group.
  #
  # config.webhook.account.groups_path = '/maestrano/account/groups/:id',
  # config.webhook.account.group_users_path = '/maestrano/account/groups/:group_id/users/:id',
  
  
  # ==> Connec Subscriptions/Webhook
  # The following section is used to configure the Connec!™ webhooks and which entities
  # you should receive via webhook.
  #
  # == Notification Path
  # This is the path of your application where notifications (created/updated entities) will
  # be POSTed to.
  # You should have a controller matching this path handling the update of your internal entities
  # based on the Connec!™ entities you receive
  #
  # config.webhook.connec.notifications_path = '/maestrano/connec/notifications'
  #
  # == Subscriptions
  # This is the list of entities (organizations,people,invoices etc.) for which you want to be
  # notified upon creation/update in Connec!™
  # 
  # config.webhook.connec.subscriptions = {
  #   accounts: true,
  #   company: true,
  #   employees: false,
  #   events: false,
  #   event_orders: false,
  #   invoices: true,
  #   items: true,
  #   journals: false,
  #   opportunities: true,
  #   organizations: true,
  #   payments: false,
  #   pay_items: false,
  #   pay_schedules: false,
  #   pay_stubs: false,
  #   pay_runs: false,
  #   people: true,
  #   projects: false,
  #   purchase_orders: false,
  #   quotes: false,
  #   sales_orders: false,
  #   tax_codes: true,
  #   tax_rates: false,
  #   time_activities: false,
  #   time_sheets: false,
  #   venues: false,
  #   warehouses: false,
  #   work_locations: false
  # }
end
```

If you need to support multiple marketplace providers, you can define configuration presets and switch between these at runtime:
```ruby
Maestrano['my-preset1'].configure do |config|
  config.environment = 'production'
  config.app.host = 'https://my-custom-provider1.com'
  ...
end

Maestrano['my-preset2'].configure do |config|
  config.environment = 'production'
  config.app.host = 'https://my-custom-provider2.com'
  ...
end
```

### Deprecated - Metadata Endpoint
Your configuration initializer is now all setup and shiny. Great! But need to know about it. Of course
we could propose a long and boring form on maestrano.com for you to fill all these details (especially the webhooks) but we thought it would be more convenient to fetch that automatically.

For that we expect you to create a metadata endpoint that we can fetch regularly (or when you press 'refresh metadata' in your maestrano cloud partner dashboard). By default we assume that it will be located at
YOUR_WEBSITE/maestrano/metadata(.json)

Of course if you prefer a different url you can always change that endpoint in your maestrano cloud partner dashboard.

What would the controller action look like? First let's talk about authentication. You don't want that endpoint to be visible to anyone. Maestrano always uses http basic authentication to contact your service remotely. The login/password used for this authentication are your actual api.id and api.key.

So here is an example of controller action for Rails to adapt depending on the framework you're using:

```ruby
class MaestranoMetaDataController < ApplicationController
  before_filter :authenticate_maestrano!
  
  def metadata
    render json: Maestrano.to_metadata
    # Or using presets
    # render json: Maestrano['my-preset'].to_metadata
  end
  
  private
    def authenticate_maestrano!
      authorized = false
      authenticate_with_http_basic do |app_id, api_token|
        authorized = Maestrano.authenticate(app_id,api_token)
      end
      unless authorized
        render json: {error: 'Invalid credentials' }, status: :unauthorized
      end
      return true
    end
end
```

## Single Sign-On Setup

> **Heads up!** Prefer to use OpenID rather than our SAML implementation? Just look at our [OpenID Guide](https://maestrano.atlassian.net/wiki/display/CONNECAPIV2/SSO+via+OpenID) to get started!

In order to get setup with single sign-on you will need a user model and a group model. It will also require you to write a controller for the init phase and consume phase of the single sign-on handshake.

You might wonder why we need a 'group' on top of a user. Well Maestrano works with businesses and as such expects your service to be able to manage groups of users. A group represents 1) a billing entity 2) a collaboration group. During the first single sign-on handshake both a user and a group should be created. Additional users logging in via the same group should then be added to this existing group (see controller setup below)

### User Setup
Let's assume that your user model is called 'User'. The best way to get started with SSO is to define a class method on this model called 'find_or_create_for_maestrano' accepting a hash of attributes - provided by Maestrano - and aiming at either finding an existing maestrano user in your database or creating a new one. Your user model should also have a :provider attribute and a :uid attribute used to identify the source of the user - Maestrano, LinkedIn, AngelList etc..

Assuming the above the method could look like this:
```ruby
# Only if you need to set a random password
require 'digest/sha1'

class User

  ...
  
  def self.find_or_create_for_maestrano(sso_hash)
    user = self.where(provider:'maestrano', uid: sso_hash[:uid]).first
    
    unless user
      user = self.new
      
      # Mapping
      user.provider = 'maestrano'
      user.uid = sso_hash[:uid]
      user.name = sso_hash[:info][:first_name]
      user.surname = sso_hash[:info][:last_name]
      user.email = sso_hash[:info][:email]
      # user.country_alpha2 = sso_hash[:info][:country]
      # user.company = sso_hash[:info][:company_name]
      # user.password = Digest::SHA1.hexdigest("#{Time.now}-#{rand(100)}")[0..20]
      # user.password_confirmation = user.password
      # user.some_other_required_field = 'some-appropriate-default-value'
      
      # Save the user
      user.save
    end
    
    return user
  end
  
  ...
  
end
```

### Group Setup
The group setup is similar to the user one. The mapping is a little easier though. Your model should also have the :provider and :uid attributes. Also your group model should have a add_member method and also a has_member? method (see controller below)

Assuming a group model called 'Organization', the find_or_create_for_maestrano class method could look like this:
```ruby
class Organization

  ...
  
  def self.find_or_create_for_maestrano(sso_hash)
    organization = self.where(provider:'maestrano', uid: sso_hash[:uid]).first
    
    unless organization
      organization = self.new
      
      # Mapping
      organization.provider = 'maestrano'
      organization.uid = sso_hash[:uid]
      organization.name = sso_hash[:info][:company_name] || 'Some default'
      # organization.principal_email = sso_hash[:info][:email]
      # organization.city = sso_hash[:info][:city]
      # organization.olson_tz = sso_hash[:info][:timezone]
      # organization.country_alpha2 = sso_hash[:info][:country]
      # organization.currency_code = sso_hash[:info][:currency]
      # organization.free_trial_end_at = sso_hash[:info][:free_trial_end_at]
      
      # Save the organization
      organization.save
    end
    
    return organization
  end
  
  ...
  
end
```

### Controller Setup
Your controller will need to have two actions: init and consume. The init action will initiate the single sign-on request and redirect the user to Maestrano. The consume action will receive the single sign-on response, process it and match/create the user and the group.

The init action is all handled via Maestrano methods and should look like this:
```ruby
def init
  redirect_to Maestrano::Saml::Request['my-preset'].new(params,session).redirect_url
end
```
The params variable should contain the GET parameters of the request. The session variable should be the actual client session.

Based on your application requirements the consume action might look like this:
```ruby
def consume
  # Process the response and extract information
  saml_response = Maestrano::Saml::Response['my-preset'].new(params[:SAMLResponse])
  user_hash = Maestrano::SSO::BaseUser.new(saml_response).to_hash
  group_hash = Maestrano::SSO::BaseGroup.new(saml_response).to_hash
  membership_hash = Maestrano::SSO::BaseMembership.new(saml_response).to_hash
  
  # Find or create the user and the organization
  user = User.find_or_create_for_maestrano(user_hash)
  organization = Organization.find_or_create_for_maestrano(group_hash)
  
  # Add user to the organization if not there already
  # Methods below should be coming from your application
  unless organization.has_member?(user)
    organization.add_member(user, role: membership_hash[:role])
  end
  
  # Set the Maestrano session (ultimately used for single logout)
  Maestrano::SSO.set_session(session, user_hash)
  
  # Sign the user in and redirect to application root
  # To be customised depending on how you handle user
  # sign in and 
  sign_in(user)
  redirect_to root_path
end
```
Note that for the consume action you should disable CSRF authenticity if your framework is using it by default. If CSRF authenticity is enabled then your app will complain on the fact that it is receiving a form without CSRF token.

### Other Controllers
If you want your users to benefit from single logout then you should define the following filter in a module and include it in all your controllers except the one handling single sign-on authentication.

```ruby
def verify_maestrano_session
  if Maestrano['my-preset'].param(:sso_enabled)
    if session && session[:maestrano] && !Maestrano::SSO['my-preset']::Session.new(session).valid?
      redirect_to Maestrano::SSO['my-preset'].init_url
    end
  end
  true
end
```

## Account Webhooks
Single sign on has been setup into your app and Maestrano users are now able to use your service. Great! Wait what happens when a business (group) decides to stop using your service? Also what happens when a user gets removed from a business? Well the controllers describes in this section are for Maestrano to be able to notify you of such events.

### Groups Controller (service cancellation)
Sad as it is a business might decide to stop using your service at some point. On Maestrano billing entities are represented by groups (used for collaboration & billing). So when a business decides to stop using your service we will issue a DELETE request to the webhook.account.groups_path endpoint (typically /maestrano/account/groups/:id).

Maestrano only uses this controller for service cancellation so there is no need to implement any other type of action - ie: GET, PUT/PATCH or POST. The use of other http verbs might come in the future to improve the communication between Maestrano and your service but as of now it is not required.

The controller example below reimplements the authenticate_maestrano! method seen in the [metadata section](#metadata) for completeness. Utimately you should move this method to a helper if you can.

The example below is for Rails and need to be adapted depending on the framework you're using:
```ruby
class MaestranoAccountGroupsController < ApplicationController
  before_filter :authenticate_maestrano!
  
  # DELETE /maestrano/account/groups/cld-1
  # Delete an entire group
  def destroy
    group_uid = params[:id]
    
    # Perform deletion steps here
    # --
    # If you need to perform a final checkout
    # then you can call Maestrano::Account::Bill.create({.. final checkout details ..})
    # --
    # If Maestrano.param('sso.creation_mode') is set to virtual
    # then you might want to delete/cancel/block all users under
    # that group
    # --
    # E.g:
    # organization = Organization.find_by_provider_and_uid('maestrano',group_uid)
    #
    # amount_cents = organization.calculate_total_due_remaining
    # Maestrano::Account::Bill.create({
    #   group_id: group_uid, 
    #   price_cents: amount_cents, 
    #   description: "Final Payout"
    # })
    # 
    # if Maestrano.param('sso.creation_mode') == 'virtual'
    #   organization.members.where(provider:'maestrano').each do |user|
    #   user.destroy
    # end
    #
    # organization.destroy
    # render json: {success: true}, status: :success
    #
  end
  
  private
    def authenticate_maestrano!
      authorized = false
      authenticate_with_http_basic do |app_id, api_token|
        authorized = Maestrano.authenticate(app_id,api_token)
      end
      unless authorized
        render json: {error: 'Invalid credentials' }, status: :unauthorized
      end
      return true
    end
end
```

### Group Users Controller (business member removal)
A business might decide at some point to revoke access to your services for one of its member. In such case we will issue a DELETE request to the webhook.account.group_users_path endpoint (typically /maestrano/account/groups/:group_id/users/:id).

Maestrano only uses this controller for user membership cancellation so there is no need to implement any other type of action - ie: GET, PUT/PATCH or POST. The use of other http verbs might come in the future to improve the communication between Maestrano and your service but as of now it is not required.

The controller example below reimplements the authenticate_maestrano! method seen in the [metadata section](#metadata) for completeness. Utimately you should move this method to a helper if you can.

The example below is for Rails and need to be adapted depending on the framework you're using:
```ruby
class MaestranoAccountGroupUsersController < ApplicationController
  before_filter :authenticate_maestrano!
  
  # DELETE /maestrano/account/groups/cld-1
  # Delete an entire group
  def destroy
    # Set the right uid based on Maestrano.param('sso.creation_mode')
    user_uid = Maestrano.mask_user(params[:id],params[:group_id]) 
    group_uid = params[:group_id]
    
    # Perform association deletion steps here
    # --
    # If Maestrano.param('sso.creation_mode') is set to virtual
    # then you might want to just delete/cancel/block the user
    #
    # E.g
    # user = User.find_by_provider_and_uid('maestrano',user_uid)
    # organization = Organization.find_by_provider_and_uid('maestrano',group_uid)
    # 
    # if Maestrano.param('sso.creation_mode') == 'virtual'
    #  user.destroy
    # else
    #   organization.remove_user(user)
    #   user.block_access! if user.reload.organizations.empty?
    # end
    #
    # render json: {success: true}, status: :success
  end
  
  private
    def authenticate_maestrano!
      authorized = false
      authenticate_with_http_basic do |app_id, api_token|
        authorized = Maestrano.authenticate(app_id,api_token)
      end
      unless authorized
        render json: {error: 'Invalid credentials' }, status: :unauthorized
      end
      return true
    end
end
```

## API
The maestrano gem also provides bindings to its REST API allowing you to access, create, update or delete various entities under your account (e.g: billing).

### Payment API
 
#### Bill
A bill represents a single charge on a given group.

```ruby
Maestrano::Account::Bill
```

##### Attributes

<table>
<tr>
<th>Field</th>
<th>Mode</th>
<th>Type</th>
<th>Required</th>
<th>Default</th>
<th>Description</th>
<tr>

<tr>
<td><b>id</b></td>
<td>readonly</td>
<td>string</td>
<td>-</td>
<td>-</td>
<td>The id of the bill</td>
<tr>

<tr>
<td><b>group_id</b></td>
<td>read/write</td>
<td>string</td>
<td><b>Yes</b></td>
<td>-</td>
<td>The id of the group you are charging</td>
<tr>

<tr>
<td><b>price_cents</b></td>
<td>read/write</td>
<td>Integer</td>
<td><b>Yes</b></td>
<td>-</td>
<td>The amount in cents to charge to the customer</td>
<tr>

<tr>
<td><b>description</b></td>
<td>read/write</td>
<td>String</td>
<td><b>Yes</b></td>
<td>-</td>
<td>A description of the product billed as it should appear on customer invoice</td>
<tr>

<tr>
<td><b>created_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the bill was created</td>
<tr>
  
<tr>
<td><b>updated_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the bill was last updated</td>
<tr>

<tr>
<td><b>status</b></td>
<td>readonly</td>
<td>String</td>
<td>-</td>
<td>-</td>
<td>Status of the bill. Either 'submitted', 'invoiced' or 'cancelled'.</td>
<tr>

<tr>
<td><b>currency</b></td>
<td>read/write</td>
<td>String</td>
<td>-</td>
<td>AUD</td>
<td>The currency of the amount charged in <a href="http://en.wikipedia.org/wiki/ISO_4217#Active_codes">ISO 4217 format</a> (3 letter code)</td>
<tr>

<tr>
<td><b>units</b></td>
<td>read/write</td>
<td>Decimal(10,2)</td>
<td>-</td>
<td>1.0</td>
<td>How many units are billed for the amount charged</td>
<tr>

<tr>
<td><b>period_started_at</b></td>
<td>read/write</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>If the bill relates to a specific period then specifies when the period started. Both period_started_at and period_ended_at need to be filled in order to appear on customer invoice.</td>
<tr>

<tr>
<td><b>period_ended_at</b></td>
<td>read/write</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>If the bill relates to a specific period then specifies when the period ended. Both period_started_at and period_ended_at need to be filled in order to appear on customer invoice.</td>
<tr>

<tr>
<td><b>third_party</b></td>
<td>read/write</td>
<td>Boolean</td>
<td>-</td>
<td>-</td>
<td>Flag for third-party bills (e.g.: charge for SMS credits). Third party bills are not subject to commissions.</td>
<tr>

</table>

##### Actions

List all bills you have created and iterate through the list
```ruby
bills = Maestrano::Account::Bill.all
bills.each { |b| puts b.id }
```

Access a single bill by id
```ruby
bill = Maestrano::Account::Bill.retrieve("bill-f1d2s54")
puts bill.group_id
```

Create a new bill
```ruby
bill = Maestrano::Account::Bill.create(group_id: "cld-3", price_cents: 2000, description: "Product purchase")
puts bill.id
```

Cancel a bill
```ruby
bill = Maestrano::Account::Bill.retrieve("bill-f1d2s54")
bill.cancel
```

##### Using presets

All actions can be performed with presets, for instance to list all bills with presets
```ruby
bills = Maestrano::Account::Bill['my-preset'].all
bills.each { |b| puts b.id }
```

#### Recurring Bill
A recurring bill charges a given customer at a regular interval without you having to do anything.

```ruby
Maestrano::Account::RecurringBill
```

##### Attributes

<table>
<tr>
<th>Field</th>
<th>Mode</th>
<th>Type</th>
<th>Required</th>
<th>Default</th>
<th>Description</th>
<tr>

<tr>
<td><b>id</b></td>
<td>readonly</td>
<td>string</td>
<td>-</td>
<td>-</td>
<td>The id of the recurring bill</td>
<tr>

<tr>
<td><b>group_id</b></td>
<td>read/write</td>
<td>string</td>
<td><b>Yes</b></td>
<td>-</td>
<td>The id of the group you are charging</td>
<tr>

<tr>
<td><b>price_cents</b></td>
<td>read/write</td>
<td>Integer</td>
<td><b>Yes</b></td>
<td>-</td>
<td>The amount in cents to charge to the customer</td>
<tr>

<tr>
<td><b>description</b></td>
<td>read/write</td>
<td>String</td>
<td><b>Yes</b></td>
<td>-</td>
<td>A description of the product billed as it should appear on customer invoice</td>
<tr>

<tr>
<td><b>period</b></td>
<td>read/write</td>
<td>String</td>
<td>-</td>
<td>Month</td>
<td>The unit of measure for the billing cycle. Must be one of the following: 'Day', 'Week', 'SemiMonth', 'Month', 'Year'</td>
<tr>

<tr>
<td><b>frequency</b></td>
<td>read/write</td>
<td>Integer</td>
<td>-</td>
<td>1</td>
<td>The number of billing periods that make up one billing cycle. The combination of billing frequency and billing period must be less than or equal to one year. If the billing period is SemiMonth, the billing frequency must be 1.</td>
<tr>

<tr>
<td><b>cycles</b></td>
<td>read/write</td>
<td>Integer</td>
<td>-</td>
<td>nil</td>
<td>The number of cycles this bill should be active for. In other words it's the number of times this recurring bill should charge the customer.</td>
<tr>

<tr>
<td><b>start_date</b></td>
<td>read/write</td>
<td>Time</td>
<td>-</td>
<td>Now</td>
<td>The date when this recurring bill should start billing the customer</td>
<tr>

<tr>
<td><b>created_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the recurring bill was created</td>
<tr>
  
<tr>
<td><b>updated_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the recurring bill was last updated</td>
<tr>

<tr>
<td><b>currency</b></td>
<td>read/write</td>
<td>String</td>
<td>-</td>
<td>AUD</td>
<td>The currency of the amount charged in <a href="http://en.wikipedia.org/wiki/ISO_4217#Active_codes">ISO 4217 format</a> (3 letter code)</td>
<tr>

<tr>
<td><b>status</b></td>
<td>readonly</td>
<td>String</td>
<td>-</td>
<td>-</td>
<td>Status of the recurring bill. Either 'submitted', 'active', 'expired' or 'cancelled'.</td>
<tr>
  
<tr>
<td><b>initial_cents</b></td>
<td>read/write</td>
<td>Integer</td>
<td><b>-</b></td>
<td>0</td>
<td>Initial non-recurring payment amount - in cents - due immediately upon creating the recurring bill</td>
<tr>

</table>

##### Actions

List all recurring bills you have created and iterate through the list
```ruby
rec_bills = Maestrano::Account::RecurringBill.all
rec_bills.each { |b| puts b.id }
```

Access a single recurring bill by id
```ruby
rec_bill = Maestrano::Account::RecurringBill.retrieve("rbill-f1d2s54")
puts rec_bill.group_id
```

Create a new recurring bill
```ruby
rec_bill = Maestrano::Account::RecurringBill.create(group_id: "cld-3", price_cents: 2000, description: "Product purchase", period: 'Month', start_date: Time.now)
puts rec_bill.id
```

Cancel a recurring bill
```ruby
rec_bill = Maestrano::Account::RecurringBill.retrieve("rbill-f1d2s54")
rec_bill.cancel
```

##### Using presets

All actions can be performed with presets, for instance to list all recurring bills with presets
```ruby
rec_bills = Maestrano::Account::RecurringBill['my-preset'].all
rec_bills.each { |b| puts b.id }
```

### Membership API
 
#### User
A user is a member of a group having access to your application. Users are currently readonly.

```ruby
Maestrano::Account::User
```

##### Attributes

<table>
<tr>
<th>Field</th>
<th>Mode</th>
<th>Type</th>
<th>Required</th>
<th>Default</th>
<th>Description</th>
<tr>

<tr>
<td><b>id</b></td>
<td>readonly</td>
<td>String</td>
<td>-</td>
<td>-</td>
<td>The id of the user</td>
<tr>

<tr>
<td><b>name</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The user first name</td>
<tr>

<tr>
<td><b>surname</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The user last name</td>
<tr>

<tr>
<td><b>email</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The user real email address</td>
<tr>

<tr>
<td><b>company_name</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The user company name as it was entered when they signed up. Nothing related to the user group name.</td>
<tr>
  
<tr>
<td><b>country</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The country of the user in <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO 3166-1 alpha-2 format</a> (2 letter code). E.g: 'US' for USA, 'AU' for Australia.</td>
<tr>

<tr>
<td><b>created_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the user was created</td>
<tr>
  
<tr>
<td><b>updated_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the user was last updated</td>
<tr>

</table>

##### Actions

List all users having access to your application
```ruby
users = Maestrano::Account::User.all;
```

Access a single user by id
```ruby
user = Maestrano::Account::User.retrieve("usr-f1d2s54");
```

##### Using presets

All actions can be performed with presets, for instance to list all users with presets
```ruby
users = Maestrano::Account::User['my-preset'].all
```

#### Group
A group represents a customer account and is composed of members (users) having access to your application. A group also represents a chargeable account (see Bill/RecurringBill). Typically you can remotely check if a group has entered a credit card on Maestrano.

Groups are currently readonly.


```ruby
Maestrano::Account::Group
```

##### Attributes

<table>
<tr>
<th>Field</th>
<th>Mode</th>
<th>Type</th>
<th>Required</th>
<th>Default</th>
<th>Description</th>
<tr>

<tr>
<td><b>id</b></td>
<td>readonly</td>
<td>String</td>
<td>-</td>
<td>-</td>
<td>The id of the group</td>
<tr>

<tr>
<td><b>name</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The group name</td>
<tr>

<tr>
<td><b>email</b></td>
<td>readonly</td>
<td>string</td>
<td><b>-</b></td>
<td>-</td>
<td>The principal email address for this group (admin email address)</td>
<tr>

<tr>
<td><b>has_credit_card</b></td>
<td>readonly</td>
<td>Boolean</td>
<td><b>-</b></td>
<td>-</td>
<td>Whether the group has entered a credit card on Maestrano or not</td>
<tr>
  
<tr>
<td><b>free_trial_end_at</b></td>
<td>readonly</td>
<td>Time</td>
<td><b>-</b></td>
<td>-</td>
<td>When the group free trial will be finishing on Maestrano. You may optionally consider this date for your own free trial (optional)</td>
<tr>

<tr>
<td><b>currency</b></td>
<td>readonly</td>
<td>String</td>
<td>-</td>
<td>-</td>
<td>The currency used by this Group in <a href="http://en.wikipedia.org/wiki/ISO_4217#Active_codes">ISO 4217 format</a> (3 letter code)</td>
<tr>

<tr>
<td><b>country</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The country of the group in <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO 3166-1 alpha-2 format</a> (2 letter code). E.g: 'US' for USA, 'AU' for Australia.</td>
<tr>

<tr>
<td><b>city</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The city of the group</td>
<tr>

<tr>
<td><b>timezone</b></td>
<td>readonly</td>
<td>String</td>
<td><b>-</b></td>
<td>-</td>
<td>The group timezone in <a href="http://en.wikipedia.org/wiki/List_of_tz_database_time_zones">Olson format</a></td>
<tr>

<tr>
<td><b>created_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the group was created</td>
<tr>

<tr>
<td><b>updated_at</b></td>
<td>readonly</td>
<td>Time</td>
<td>-</td>
<td>-</td>
<td>When the group was last updated</td>
<tr>

</table>

##### Actions

List all groups having access to your application
```ruby
groups = Maestrano::Account::Group.all;
```

Access a single group by id
```ruby
group = Maestrano::Account::Group.retrieve("usr-f1d2s54");
```

##### Using presets

All actions can be performed with presets, for instance to list all groups with presets
```ruby
groups = Maestrano::Account::Group['my-preset'].all
```

## Connec!™ Data Sharing
Maestrano offers the capability to share actual business data between applications via its data sharing platform Connec!™.

The platform exposes a set of RESTful JSON APIs allowing your application to receive data generated by other applications and update data in other applications as well!

Connec!™ also offers the ability to create webhooks on your side to get automatically notified of changes happening in other systems. 

Connec!™ enables seamless data sharing between the Maestrano applications as well as popular apps such as QuickBooks and Xero. One connector - tens of integrations!

### Making Requests

Connec!™ REST API documentation can be found here: http://maestrano.github.io/connec

The Maestrano API provides a built-in client - based on HTTParty - for connecting to Connec!™. Things like connection and authentication are automatically managed by the Connec!™ client.


```ruby
# Pass the customer group id as argument
client = Maestrano::Connec::Client.new("cld-f7f5g4")

# Retrieve all organizations (customers and suppliers) created in other applications
resp = client.get('/organizations')
resp.body # returns the raw response "{\"organizations\":[ ... ]}"
resp.parsed_response # returns a ruby hash { "organizations": [ ... ] }

# Create a new organization
client.post('/organizations', { organizations: { name: "DoeCorp Inc."} })

# Update an organization
client.put('/organizations/e32303c1-5102-0132-661e-600308937d74', { organizations: { is_customer: true} })

# With presets
client_presets = Maestrano::Connec::Client['my-preset'].new("cld-f7f5g4")
client_presets.get('/organizations')
```



### Webhook Notifications
If you have configured the Maestrano API to receive update notifications (see 'subscriptions' configuration at the top) from Connec!™ then you can expect to receive regular POST requests on the notification_path you have configured.

Notifications are JSON messages containing the list of entities that have recently changed in other systems. You will only receive notifications for entities you have subscribed to.

Example of notification message:
```ruby
{
  "organizations": [
    { "id": "e32303c1-5102-0132-661e-600308937d74", name: "DoeCorp Inc.", ... }
  ],
  "people": [
    { "id": "a34303d1-4142-0152-362e-610408337d74", first_name: "John", last_name: "Doe", ... }
  ]
}
```

Entities sent via notifications follow the same data structure as the one described in our REST API documentation (available at http://maestrano.github.io/connec)


## Support
This README is still in the process of being written and improved. As such it might not cover some of the questions you might have.

So if you have any question or need help integrating with us just let us know at support@maestrano.com

## License

MIT License. Copyright 2015 Maestrano Pty Ltd. https://maestrano.com

You are not granted rights or licenses to the trademarks of Maestrano.
