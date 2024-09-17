# Use an appropriate base image, such as Ubuntu
FROM ubuntu:latest

# Install OpenSSH server
RUN apt-get update && \
    apt-get install -y openssh-server && \
    mkdir /var/run/sshd

# Set the root password
RUN echo 'root:root' | chpasswd

# Configure OpenSSH server
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Start OpenSSH server
CMD ["/usr/sbin/sshd", "-D"]
