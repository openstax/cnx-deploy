# Run cnx plone site in docker:
#
# cp ~/.ssh/id_rsa . # so that it's possible to checkout git repos
#                    # the ssh key is removed later so it is not in the image
# docker build -t cnxdeploy_plone -f plone.Dockerfile .
# docker run --name=cnxdeploy_plone_run -d cnxdeploy_plone
# # gets the IP address of the docker container
# docker inspect --format='{{.NetworkSettings.IPAddress}}' cnxdeploy_plone_run
# # go to http://<ip-address-of-container>:8888/ to view the site

FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y git python-virtualenv python-dev libssl-dev

RUN mkdir /var/www
RUN echo "www-data ALL=NOPASSWD:ALL" >>/etc/sudoers
RUN ssh-keyscan -H github.com >>/etc/ssh/ssh_known_hosts

RUN echo "Please copy your ssh key for github to this directory as "id_rsa", required to checkout Connexions/oer.exports"
COPY id_rsa /var/www/.ssh/id_rsa
RUN chown -R www-data:www-data /var/www

USER www-data
WORKDIR /var/www

RUN git clone https://github.com/Connexions/cnx-deploy.git
WORKDIR /var/www/cnx-deploy
RUN git clone https://github.com/ansible/ansible.git
WORKDIR ansible
RUN git submodule update --init --recursive

WORKDIR /var/www/cnx-deploy
RUN virtualenv .
RUN ./bin/pip install ./ansible
RUN ./bin/ansible-playbook -vvv -i environments/local/inventory plone.yml
RUN rm /var/www/.ssh/id_rsa # remove ssh key

RUN sudo apt-get clean && sudo rm  -rf /var/lib/apt/lists/* # make the image smaller
RUN sudo sed -i '/^www-data/ D' /etc/sudoers # remove sudo privileges for www-data

WORKDIR /var/www/cnx/src/cnx-buildout
RUN ./bin/zeoserver stop
RUN ./bin/instance stop
CMD ./bin/zeoserver start && ./bin/instance fg
