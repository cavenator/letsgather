echo "if you haven't done so already, create the database for this env"
echo "migrating db"
rake db:migrate
echo "starting server"
foreman start
echo "foreman running"
