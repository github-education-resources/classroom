module LtiConfigurationHelper
  def lms_type_select_options(default_name: "Other Learning Management System")
    LtiConfiguration.lms_types.collect do |k,v|
      if k == "other"
        [default_name, k]
      else
        [v,k]
      end
    end
  end
end
