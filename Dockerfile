FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    wget \
    curl \
    git \
    ssh \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    ansible==8.6.1 \
    paramiko \
    netmiko \
    pynetbox \
    requests \
    pyyaml \
    jinja2 \
    mysql-connector-python

# Install Ansible collections
RUN ansible-galaxy collection install arista.eos
RUN ansible-galaxy collection install cisco.ios
RUN ansible-galaxy collection install cisco.nxos
RUN ansible-galaxy collection install cisco.iosxr
RUN ansible-galaxy collection install extreme.exos
RUN ansible-galaxy collection install community.aws
RUN ansible-galaxy collection install azure.azcollection
RUN ansible-galaxy collection install google.cloud
RUN ansible-galaxy collection install community.network
RUN ansible-galaxy collection install ansible.netcommon

# Download and install Semaphore v2.15.0 (latest stable version)
RUN wget -O /tmp/semaphore.tar.gz https://github.com/semaphoreui/semaphore/releases/download/v2.15.0/semaphore_2.15.0_linux_amd64.tar.gz \
    && tar -xzf /tmp/semaphore.tar.gz -C /usr/local/bin/ && rm /tmp/semaphore.tar.gz \
    && chmod +x /usr/local/bin/semaphore

# Create directories
RUN mkdir -p /etc/semaphore/ssh_keys \
    && mkdir -p /etc/semaphore/data \
    && mkdir -p /project_outputs

# Create semaphore user but keep root for initial setup
RUN useradd -m -s /bin/bash semaphore \
    && chown -R semaphore:semaphore /etc/semaphore \
    && chown -R semaphore:semaphore /project_outputs

# Expose port
EXPOSE 3000

# Start Semaphore server using environment variables
CMD ["sh", "-c", "semaphore setup --env && semaphore server"]
