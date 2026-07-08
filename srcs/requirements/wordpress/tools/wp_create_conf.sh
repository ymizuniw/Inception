curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

# Check Installation
# curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.asc
# curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/wp-cli.pgp | gpg --import
# gpg --verify wp-cli.phar.asc wp-cli.phar

# php wp-cli.phar --info

# Set wp alias
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# download wordpress if exec as a root user is allowed
wp core download --path="/var/www/wordpress" --allow-root

cd "/var/www/wordpress"
wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$(cat /run/secrets/db_password.txt)" --allow-root
