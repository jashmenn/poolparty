=begin rdoc
  Cloud extensions for the DependencyResolver
=end

module PoolParty
  # Take the cloud dependency tree
  module DependencyResolverCloudExtensions    
    def to_properties_hash
      {
        :options => options,
        :services => services.keys.map {|k| {k => services[k].to_properties_hash } }.first,
        :resources => resources.keys.inject({}) do |sum,k| 
          sum.merge(Hash[k.to_sym, resources[k].map {|a| a.to_properties_hash } ])
        end
      }
    end
    
  end
  
  # Adds the to_properties_hash method on top of resources, the lowest level
  module DependencyResolverResourceExtensions
    def to_properties_hash
      {
        :options => options
      }
    end
  end
end