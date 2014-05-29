<p align="center">
<img src="https://raw.github.com/maestrano/maestrano-rails/master/maestrano.png" alt="Maestrano Logo">
</p>

Maestrano Cloud Integration is currently in closed beta. Want to know more? Send us an email to <contact@maestrano.com>.

## Getting Setup
Before integrating with us you will need an API Key. Maestrano Cloud Integration being still in closed beta you will need to contact us beforehand to gain production access.

For testing purpose we provide an API Sandbox where you can freely obtain an API Token. The sandbox is great to test single sign-on and API integration (e.g: billing API).

To get started just go to: http://api-sandbox.maestrano.io

## Getting Started with Rails

If you're looking at integrating Maestrano in your Rails application then you should use the maestrano-rails gem.

More details on the [maestrano-rails project page](https://github.com/maestrano/maestrano-rails).

## Getting Started
The first step is create an initializer to configure the behaviour of the Maestrano gem - including setting your API key.

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
  config.environment = 'test' # or 'production'
  
  # ==> API key
  # Your application API key which you can retrieve on http://maestrano.com
  # via your cloud partner dashboard.
  # For testing you can retrieve/generate an api_key from the API Sandbox directly 
  # on http://api-sandbox.maestrano.io
  config.api_key = (config.environment == 'production' ? 'prod_api_key' : 'sandbox_api_key')
  
  # ==> Single Sign-On activation
  # Enable/Disable single sign-on. When troubleshooting authentication issues
  # you might want to disable SSO temporarily
  config.sso_enabled = true
  
  # ==> Application host
  # This is your application host (e.g: mysuperapp.com) which is ultimately
  # used to redirect users to the right SAML url during SSO handshake.
  config.app_host = (config.environment == 'production' ? 'https://my-production-app.com' : 'http://localhost:3000')
  
  # ==> SSO Initialization endpoint
  # This is your application path to the SAML endpoint that allows users to
  # initialize SSO authentication. Upon reaching this endpoint users your
  # application will automatically create a SAML request and redirect the user
  # to Maestrano. Maestrano will then authenticate and authorize the user. Upon
  # authorization the user gets redirected to your application consumer endpoint
  # (see below) for initial setup and/or login.
  # The controller for this path is automatically
  # generated when you run 'rake maestrano:install' and is available at
  # <rails_root>/app/controllers/maestrano/auth/saml.rb
  config.sso_app_init_path = '/maestrano/auth/saml/init'
  
  # ==> SSO Consumer endpoint
  # This is your application path to the SAML endpoint that allows users to
  # finalize SSO authentication. During the 'consume' action your application
  # sets users (and associated group) up and/or log them in.
  # The controller for this path is automatically
  # generated when you run 'rake maestrano:install' and is available at
  # <rails_root>/app/controllers/maestrano/auth/saml.rb
  config.sso_app_consume_path = '/maestrano/auth/saml/consume'
  
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
  # In this case you would set the 'user_creation_mode' to 'real' which means that the uid
  # and email we pass to you are the actual user email and maestrano universal id.
  #
  # == mode: 'virtual'
  # Now let's say that due to technical constraint your application cannot authorize a user
  # to belong to several groups. Well next time John logs in via a different group there will
  # be a problem: the user already exists (based on uid or email) and cannot be assigned 
  # to a second group. To fix this you can set the 'user_creation_mode' to 'virtual'. In this
  # mode users get assigned a truly unique uid and email across groups. So next time John logs
  # in a whole new user account can be created for him without any validation problem. In this
  # mode the email we assign to him looks like "usr-sdf54.cld-45aa2@mail.maestrano.com". But don't
  # worry we take care of forwarding any email you would send to this address
  #
  config.user_creation_mode = 'virtual' # or 'real'
end
```

## Single Sign-On Setup
In order to get setup with single sign-on you will need a user model and a group model. It will also require you to write a controller for the init phase and consume phase of the single sign-on handshake.

You might wonder why we need a 'group' on top of a user. Well Maestrano works with businesses and as such expects your service to be able to manage groups of users. A group represents 1) a billing entity 2) a collaboration group. During the first single sign-on handshake both a user and a group should be created. Additional users logging in via the same group should then be added to this existing group (see controller setup below)

### User Setup
Let's assume that your user model is called 'User'. The best way to get started with SSO is to define a method on this model called find_or_create_for_maestrano
