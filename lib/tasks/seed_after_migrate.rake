# On a new database, db:migrate loads db/schema.rb and skips the SQL in the migrations, so the roles are not created.
Rake::Task["db:migrate"].enhance { Rake::Task["db:seed"].invoke }
