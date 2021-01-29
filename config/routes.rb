Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'storage#index'
  get 'storage', to: 'storage#index'
  get 'home', to: 'home#index'

  scope(:path => '/profile') do
    post 'changeColor', to: 'profile#changeColor'

    get '', to: 'profile#index'
  end

  scope(:path => '/biosignals') do
    get 'advancedSearch', to: 'biosignals#advancedSearch'
    get 'getUserFavorites', to: 'biosignals#favorites'
    get 'getUserBiosignals', to: 'biosignals#getUserBiosignals'
    get ':signalId', to: 'biosignals#show'
    get ':signalId/d3', to: 'biosignals#dataToD3'

    post ':signalId/shareGroup', to: 'biosignals#shareWithGroup'
    post ':signalId/addToFavorites', to: 'biosignals#addToFavorites'
    post ':signalId/createAnnotation', to: 'biosignals#createAnnotation'

    delete ':signalId/annotations/:annotationId', to: 'biosignals#deleteAnnotation'
    delete ':signalId', to: 'biosignals#delete'
  end

  scope(:path => '/groups') do
    get 'getUserGroups', to: 'groups#getUserGroups'
    get ':groupId/members', to: 'groups#members'
    post ':groupId/addUser', to: 'groups#addUser'
  end

  scope(:path => '/biosignalgroups') do
    post ':biosignalGroupId/shareBiosignal', to: 'biosignal_groups#addBiosignalToBiosignalGroup'
    post ':biosignalGroupId/share', to: 'biosignal_groups#shareWithGroup'
    get 'getUserBiosignalGroups', to: 'biosignal_groups#getUserBiosignalGroups'
    get ':biosignalGroupId', to: 'biosignal_groups#show'

    patch ':biosignalGroupId/videoRange', to: 'biosignal_groups#videoRange'
    delete ':biosignalGroupId/unshare', to: 'biosignal_groups#removeFromBiosignalGroup'
  end

  scope(:path => '/api') do
    get 'user', to: 'api#user'
    get 'biosignal/:signalId', to: 'api#biosignal'
  end

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  resources :biosignals
  resources :groups
  resources :biosignal_groups
end
