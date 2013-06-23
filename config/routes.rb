MaximusSamurai::Application.routes.draw do

  devise_for :views

	match 'events/:id/supplemental_info' => 'events#supplemental_info'
	match 'events/:id/supplmenetal_info/edit' => 'events#edit_supplemental_info'
	match 'events/:id/change_location' => 'events#edit_location'
	get 'events/:id/description', :to => 'events#description'
	get 'events/:id/group_email', :to => 'events#group_email'
	get 'events/:id/send_group_email', :to => 'events#send_group_email'
	get 'events/:id/email_host', :to => 'events#email_host'
	get 'events/:id/send_host_email', :to => 'events#send_host_email'
	get 'events/:id/attending_guests', :to => 'events#attending_guests'
	get 'events/:id/unattending_guests', :to => 'events#unattending_guests'
	get 'events/:id/undecided_guests', :to => 'events#undecided_guests'
	get 'events/:id/potluck_statistics', :to => 'events#potluck_statistics'
	get 'events/:id/get_host_groups', :to => 'events#get_host_groups'
	delete 'events/:id/remove_from_event/:user_id', :to => 'events#remove_from_event'
	get 'users/:user_id/groups(.:format)', :to => 'groups#index'
	post 'users/:user_id/groups(.:format)',:to => 'groups#create'
	get  'users/:user_id/groups/new(.:format)', :to => 'groups#new'
	get 'users/:user_id/groups/:id(.:format)', :to => 'groups#show'
	get 'users/:user_id/groups/:id/edit(.:format)', :to => 'groups#edit'
	put 'users/:user_id/groups/:id(.:format)', :to => 'groups#update'
	delete 'users/:user_id/groups/:id(.:format)', :to => 'groups#destroy'
	get '/faq', :to => 'events#faq'
	put 'events/:id/change_roles/:attendee_id(.:format)', :to => 'events#change_roles'
	get 'users/:user_id/event_settings(.:format)', :to => 'event_settings#get_settings'
	put 'users/:user_id/event_settings/:id(.:format)', :to => 'event_settings#update_event_settings'

	resources :events do
		get 'attendees/add_attendees', :to => 'attendees#add_attendees'
		post 'attendees/invite_guests', :to => 'attendees#invite_guests'
		get 'attendees/send_updated_calendar', :to => 'attendees#send_updated_calendar'
		post 'attendees/:id/rsvp', :to => 'attendees#rsvp'
		get 'attendees/:id/send_calendar', :to => 'attendees#send_individual_calendar'
		get 'attendees/:id/email_guest', :to => "attendees#email_guest"
		get 'attendees/:id/send_guest_email', :to => "attendees#send_guest_email"
		resources :attendees 
		resources :potluck_items
  end

  devise_for :users

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
   root :to => 'events#index'


	devise_scope :user do
  	get "/", :to => 'devise/sessions#new'
  end

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
