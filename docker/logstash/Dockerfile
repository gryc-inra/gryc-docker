FROM docker.elastic.co/logstash/logstash:5.5.1

# Add your logstash plugins setup here
# Example: RUN logstash-plugin install logstash-filter-json

ADD config/logstash.yml /usr/share/logstash/config/logstash.yml
ADD pipeline/logstash.conf /usr/share/logstash/pipeline/logstash.conf
