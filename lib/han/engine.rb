
module Han
  class Engine < Rails::Engine
    
    config.to_prepare do
      ::Jurisdiction.send(:include, Models::Jurisdiction)
      ::Role.send(:include, Models::Role)
      ::Target.send(:include, Models::Target)
      ::Audience.send(:include, Models::Audience)
      ::User.send(:include, Models::User)
      ::Organization.send(:include, Models::Organization)
      ::AuditsController.send(:add_model,'HanAlert')
    end
    
  end
end