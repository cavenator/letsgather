echo "creating db"
rake db:create
echo "building db"
rake db:migrate
echo "starting server"
foreman start
echo "ruby server running"
