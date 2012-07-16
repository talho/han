require 'csv'

han = App.find_by_name('han')

CSV.open(File.dirname(__FILE__) + '/roles.csv', :headers => true) do |roles|
  roles.each do |row|
    Role.find_or_create_by_name(:name => row['role']) { |role|
      role.public = row['approval_required'].downcase == 'false'
      role.alerter = row['alerter']
      role.app_id = han.id
    }
  end
end

Role.public('han')
Role.admin('han')
Role.superadmin('han')
