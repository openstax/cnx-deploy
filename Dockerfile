FROM ubuntu:16.04

RUN addgroup --system admin \
    && adduser --system --group admin

# Install dependencies
RUN set -e \
    && apt-get update \
    && apt-get install -y python-yaml python-jinja2 python-pip sudo \
    && rm -rf /var/lib/apt/lists/*

RUN set -e \
    && adduser admin sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install the software
COPY requirements.txt /code/requirements.txt
RUN set -e \
    && pip install -r /code/requirements.txt

# Mount the code
COPY . /code/

USER admin
WORKDIR /code

ENV ENVIRON container
ENV INVENTORY environments/${ENVIRON}/inventory

# Run each playbook individually to allow us to progressively debug
# +++
# Persistence services
# +++
RUN ansible-playbook -v -i ${INVENTORY} pretask.yml
RUN ansible-playbook -v -i ${INVENTORY} nfs.yml
RUN ansible-playbook -v -i ${INVENTORY} nfs_connected.yml
RUN ansible-playbook -v -i ${INVENTORY} database.yml
RUN ansible-playbook -v -i ${INVENTORY} broker.yml
# +++
# Applications
# +++

RUN ansible-playbook -v -i ${INVENTORY} archive.yml not_standalone=yes
RUN ansible-playbook -v -i ${INVENTORY} publishing.yml not_standalone=yes
RUN ansible-playbook -v -i ${INVENTORY} database_migration.yml
RUN ansible-playbook -v -i ${INVENTORY} channel_processing.yml
RUN ansible-playbook -v -i ${INVENTORY} publishing_worker.yml
RUN ansible-playbook -v -i ${INVENTORY} authoring.yml
RUN ansible-playbook -v -i ${INVENTORY} press.yml
RUN ansible-playbook -v -i ${INVENTORY} press_worker.yml
RUN ansible-playbook -v -i ${INVENTORY} zope.yml not_standalone=yes
RUN ansible-playbook -v -i ${INVENTORY} legacy_frontend.yml
RUN ansible-playbook -v -i ${INVENTORY} frontend.yml not_standalone=yes
RUN ansible-playbook -v -i ${INVENTORY} lead_frontend.yml
RUN ansible-playbook -v -i ${INVENTORY} iptables.yml
RUN ansible-playbook -v -i ${INVENTORY} sysstat.yml
RUN ansible-playbook -v -i ${INVENTORY} update_versions.yml
RUN ansible-playbook -v -i ${INVENTORY} run_deferred_migrations.yml

# front-end ports
EXPOSE 80/tcp
EXPOSE 443/tcp

# other service ports
EXPOSE 8080/tcp
# TODO: I don't know all the ports off the top of my head, so gotta look those up and get them defined here.
