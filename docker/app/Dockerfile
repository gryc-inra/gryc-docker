FROM php:7.1.8-fpm

# Install wget, git, mafft and libraries needed by php extensions
RUN apt-get update; \
    apt-get install -y \
            zlib1g-dev \
            wget \
            git \
            mafft \
            supervisor \
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
RUN docker-php-ext-configure intl --with-icu-dir=/usr/local; \
    docker-php-ext-install intl pdo pdo_mysql zip bcmath; \
    docker-php-ext-enable opcache

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
ENV GRYC_VERSION=0.2-dev
RUN curl -o gryc.tar.gz -fSL "https://github.com/mpiot/gryc/archive/${GRYC_VERSION}.tar.gz"; \
	tar -xzf gryc.tar.gz -C /var/www/html --strip 1; \
	rm gryc.tar.gz; \
	rm .gitignore Gruntfile.js package.json README.md web/config.php web/app_dev.php; \
	chown -R www-data:www-data /var/www/html

# Install app dependencies
RUN composer install --no-suggest --optimize-autoloader
RUN chown -R www-data:www-data . && chmod -R 777 var/cache var/logs

# Copy the entrypoint file and define it
COPY ./docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# Copy the supervisor configuration file and define it as CMD
COPY ./supervisor-programs.conf /etc/supervisor/conf.d/supervisor-programs.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
