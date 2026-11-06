namespace :roles do
  desc "Create the default roles that do not exist"
  task ensure: :environment do
    Role.ensure_defaults!
  end
end

# On a new database, db:migrate loads db/schema.rb and skips the SQL in the migrations, so the roles are not created.
# A migration with VERSION can target a schema that has no roles table or that has older role names.
Rake::Task["db:migrate"].enhance { Rake::Task["roles:ensure"].invoke unless ENV["VERSION"] }
