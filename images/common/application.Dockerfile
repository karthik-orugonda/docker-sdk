FROM ${SPRYKER_PLATFORM_IMAGE} AS application-basic
LABEL "spryker.image" "none"

ENV SPRYKER_IN_DOCKER=1
ENV COMPOSER_IGNORE_CHROMEDRIVER=1
{% for envName, envValue in _envs %}
ENV {{ envName }}='{{ envValue }}'
{% endfor %}

WORKDIR /data

# Create log directory
ARG SPRYKER_LOG_DIRECTORY
ENV SPRYKER_LOG_DIRECTORY=${SPRYKER_LOG_DIRECTORY}
RUN mkdir -p ${SPRYKER_LOG_DIRECTORY} && \
chown spryker:spryker ${SPRYKER_LOG_DIRECTORY}

# Creates the list of known hosts
ARG KNOWN_HOSTS
RUN mkdir -p /home/spryker/.ssh && chmod 0700 /home/spryker/.ssh
RUN bash -c '[ ! -z "${KNOWN_HOSTS}" ] && ssh-keyscan -t rsa ${KNOWN_HOSTS} >> /home/spryker/.ssh/known_hosts || true'
RUN chown spryker:spryker -R /home/spryker/.ssh

# PHP-FPM environment variables
ENV PHP_FPM_PM=dynamic
ENV PHP_FPM_PM_MAX_CHILDREN=4
ENV PHP_FPM_PM_START_SERVERS=2
ENV PHP_FPM_PM_MIN_SPARE_SERVERS=1
ENV PHP_FPM_PM_MAX_SPARE_SERVERS=2
ENV PHP_FPM_PM_MAX_REQUESTS=500
ENV PHP_FPM_REQUEST_TERMINATE_TIMEOUT=1m

# PHP configuration
ARG DEPLOYMENT_PATH
COPY ${DEPLOYMENT_PATH}/context/php/php-fpm.d/worker.conf /usr/local/etc/php-fpm.d/worker.conf
RUN bash -c "php -r 'exit(PHP_VERSION_ID > 70400 ? 1 : 0);' && sed -i '' -e 's/decorate_workers_output/;decorate_workers_output/g' /usr/local/etc/php-fpm.d/worker.conf || true"
COPY ${DEPLOYMENT_PATH}/context/php/php.ini /usr/local/etc/php/
COPY ${DEPLOYMENT_PATH}/context/php/conf.d/90-opcache.ini /usr/local/etc/php/conf.d
# removing default opcache.ini
RUN rm -f /usr/local/etc/php/conf.d/opcache.ini

{% if _phpExtensions is defined and _phpExtensions is not empty %}
{% for phpExtention in _phpExtensions %}
RUN mv /usr/local/etc/php/disabled/{{phpExtention}}.ini /usr/local/etc/php/conf.d/90-{{phpExtention}}.ini
{% endfor %}
{% endif %}

COPY ${DEPLOYMENT_PATH}/context/php/conf.d/99-from-deploy-yaml-php.ini /usr/local/etc/php/conf.d/

# Jenkins
COPY --chown=spryker:spryker ${DEPLOYMENT_PATH}/context/jenkins/jenkins.docker.xml.twig /home/spryker/jenkins.docker.xml.twig

# Build info
COPY --chown=spryker:spryker ${DEPLOYMENT_PATH}/context/php/build.php /home/spryker/build.php