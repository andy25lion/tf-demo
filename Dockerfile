FROM ubuntu

RUN apt-get update
RUN apt-get install -y gnupg software-properties-common wget

RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
&& echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list

RUN apt-get update && apt-get install -y terraform

RUN touch ~/.bashrc && terraform -install-autocomplete