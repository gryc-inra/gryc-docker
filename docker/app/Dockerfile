FROM php:7.1.9-fpm

# Add repositories
RUN apt-get update; \
    apt-get install -y apt-transport-https; \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -; \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list; \
    curl -sL https://deb.nodesource.com/setup_8.x | bash -;

# Install wget, git, mafft and libraries needed by php extensions
RUN apt-get install -y \
            zlib1g-dev \
            wget \
            git \
            mafft \
            supervisor \
            nodejs \
            yarn \
    ; \
    rm -rf /var/lib/apt/lists/*

# Compile ICU (required by intl php extension)
RUN curl -sS -o /tmp/icu.tar.gz -L http://download.icu-project.org/files/icu4c/59.1/icu4c-59_1-src.tgz; \
    tar -zxf /tmp/icu.tar.gz -C /tmp; \
    cd /tmp/icu/source; \
    ./configure --prefix=/usr/local; \
    make; \
    make install

# To avoid a bug with the intl extension compilation
# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"

# Configure, install and enable php extensions
RUN docker-php-source extract \
    && docker-php-ext-configure intl --with-icu-dir=/usr/local \
    && docker-php-ext-install intl pdo pdo_mysql zip bcmath \
    && docker-php-ext-enable opcache \
    && docker-php-source delete

RUN pecl install apcu-5.1.8 \
    && docker-php-ext-enable apcu

# Install Composer
RUN php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin --filename=composer && chmod +x /usr/local/bin/composer

# Copy the php.ini file
COPY ./php.ini /usr/local/etc/php/
COPY ./php-cli.ini /usr/local/etc/php/

# Download, extract and remove BLAST archive
RUN cd /opt && wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.6.0+-x64-linux.tar.gz && \
    tar zxvpf ncbi-blast-2.6.0+-x64-linux.tar.gz && \
    rm ncbi-blast-2.6.0+-x64-linux.tar.gz

# Set environment variables for BLAST
ENV PATH=$PATH:/opt/ncbi-blast-2.6.0+/bin

# Define the working directory
WORKDIR /var/www/html

# Download the Gryc source code
ENV GRYC_VERSION=2017.10.10-dev
RUN curl -o gryc.tar.gz -fSL "https://github.com/mpiot/gryc/archive/${GRYC_VERSION}.tar.gz"; \
	tar -xzf gryc.tar.gz -C /var/www/html --strip 1; \
	rm gryc.tar.gz; \
	rm .gitignore .php_cs.dist phpunit.xml.dist README.md web/config.php web/app_dev.php; \
	chown -R www-data:www-data /var/www/html

# Compile assets
RUN yarn install; \
    yarn prod; \
    rm -R node_modules/; \
    apt-get autoremove -y --purge nodejs yarn;

# Install app dependencies
RUN composer install --no-suggest --optimize-autoloader
RUN chown -R www-data:www-data . && chmod -R 777 var/cache var/logs

# Copy script and supervisor conf
COPY ./init.sh /opt/app/init.sh
COPY ./supervisor-programs.conf /etc/supervisor/conf.d/supervisor-programs.conf

# Execute the sript
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
