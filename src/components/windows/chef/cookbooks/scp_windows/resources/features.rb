property :features_options, Hash, required: true

default_action :install

action :install do
  new_resource.features_options.each do |feature_name, feature_options|
    scp_windows_feature feature_name do
      feature_options feature_options ? feature_options : {}
      action :install
    end
  end
end
