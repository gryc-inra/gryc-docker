FROM docker.elastic.co/logstash/logstash:5.1.1

# Add your logstash plugins setup here
# Example: RUN logstash-plugin install logstash-filter-json

RUN rm -f /usr/share/logstash/pipeline/logstash.conf
ADD pipeline/ /usr/share/logstash/pipeline/
